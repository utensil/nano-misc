require 'open-uri'
require File.expand_path('../sem_ver', __FILE__)

class VersionedGem
  
    #http://docs.rubygems.org/read/chapter/16#page74
    # =  Equals version
  # != Not equal to version
  # >  Greater than version
  # <  Less than version
  # >= Greater than or equal to
  # <= Less than or equal to
  # ~> Approximately greater than 
     # (see "Pessimistic Version Constraint" below)
  def self.parse_constraint(gem_constraint)
    #http://docs.rubygems.org/read/chapter/16#page74
      # =  Equals version
    # != Not equal to version
    # >  Greater than version
    # <  Less than version
    # >= Greater than or equal to
    # <= Less than or equal to
    # ~> Approximately greater than 
       # (see "Pessimistic Version Constraint" below)  
    return ['>', '0.0.0'] if gem_constraint.nil? || gem_constraint == "" || 
                              gem_constraint.match(/^\s*>[=]?\s*0\s*$/)     
       
    matched = gem_constraint.match /^\s*([!=><~]+)?\s*((\d+)\.(\d+)(\.(\d+))?(\.?[A-Za-z0-9][0-9A-Za-z\-.]*)?)\s*(,.*)?$/
    
    raise "Invalid gem constraint[#{gem_constraint}]" if matched.nil?
    #FIXME 
    #puts "WARN: Ignoring more than one gem contraint except the first one for [#{matched.inspect}] in [#{gem_constraint}]" if matched[7] != ''
    
    rel = matched[1] || '='
    
    [rel, matched[2]]
  end
  
  #http://guides.rubygems.org/rubygems-org-api/
  # GET - /api/v1/dependencies?gems=[COMMA DELIMITED GEM NAMES]
  # Returns a marshalled array of hashes for all versions of given gems. Each hash contains a gem version with its dependencies making this useful for resolving dependencies.
  # 
  # $ ruby -ropen-uri -rpp -e \
    # 'pp Marshal.load(open("https://rubygems.org/api/v1/dependencies?gems=rails,thor"))'
  # 
  # [{:platform=>"ruby",
    # :dependencies=>
     # [["bundler", "~> 1.0"],
      # ["railties", "= 3.0.3"],
      # ["actionmailer", "= 3.0.3"],
      # ["activeresource", "= 3.0.3"],
      # ["activerecord", "= 3.0.3"],
      # ["actionpack", "= 3.0.3"],
      # ["activesupport", "= 3.0.3"]],
    # :name=>"rails",
    # :number=>"3.0.3"},
  # ...
  # {:number=>"0.9.9", :platform=>"ruby", :dependencies=>[], :name=>"thor"}]

  def self.get_all_dependencies(gem_name)
    deps = Marshal.load(open("http://rubygems.org/api/v1/dependencies?gems=#{gem_name}"))
  end

  def self.get_dependencies(gem_name, version)
    deps = get_all_dependencies(gem_name)
    vg_dep = nil
    deps.each do |dep|
      if dep[:number] == version
        vg_dep = dep[:dependencies]
        break
      end
    end
    raise "#{gem_name} doesn't have a version of #{version} in #{deps}!" if vg_dep.nil?
    
    vg_dep
  end
  
  def self.dependencies_to_version_hash(deps)
    vers = {}
    deps.each do |dep|
      vers[dep[:number]] = dep
    end
    vers
  end

  def self.dependencies_to_version_array(deps)
    vers = []
    deps.each do |dep|
      vers << dep[:number]
    end
    vers
  end
  
  def self.upper_bound(version)
    matched = version.match /^\s*(\d+)\.(\d+)(\.(\d+))?\s*$/
    raise "Invalid pessimistic version constraint[~>#{version}]" if matched.nil?
    
    if matched[3].nil?
      #2-digit
      return "#{matched[1].to_i + 1}.0"
    else
      #3-digit
      return "#{matched[1]}.#{matched[2].to_i + 1}.0"
    end  
  end
  
  def self.select_version(versions, constraint, options = {})
    raise "Invalid constraint [#{constraint.to_s}]" unless constraint.instance_of?(Array) && constraint.size == 2
    raise "invalid versions [#{versions.to_s}]" unless versions.instance_of?(Array)
    
    options = { :pre => false }.merge(options)
    include_pre = options[:pre]
    
    qv, rv = constraint[0], constraint[1]    
    ver = SemVer.new rv
    
    #'=', '!=', '>', '<', '>=', '<=', '~>'
    # (include_pre || !sv.pre?) # => either include pre or exclude pre
    
    best_version = case qv
    when '='
      versions.select do |v|
        sv = SemVer.new(v)
        sv == ver && (include_pre || !sv.pre?) #either include pre or exclude pre
      end
    when '!='
      versions.select do |v|
        sv = SemVer.new(v)
        sv != ver && (include_pre || !sv.pre?) 
      end
    when '>='
      versions.select do |v|
        sv = SemVer.new(v)
        sv >= ver && (include_pre || !sv.pre?) 
      end
    when '>'
      versions.select do |v|
        sv = SemVer.new(v)
        sv > ver && (include_pre || !sv.pre?) 
      end
    when '<='
      versions.select do |v|
        sv = SemVer.new(v) 
        sv <= ver && (include_pre || !sv.pre?) 
      end 
    when '<'
      versions.select do |v|
        sv = SemVer.new(v) 
        sv < ver && (include_pre || !sv.pre?)
      end  
    when '~>'
      uv = SemVer.new(self.upper_bound(rv))
      versions.select do |v| 
        sv = SemVer.new(v)       
        sv >= ver && sv < uv && (include_pre || !sv.pre?)
      end
    else
      raise "Invalid constraint symbol [#{qv}]"
    end
    
    best_version = best_version.max_by { |v| SemVer.new(v) }
    raise "No best version found for #{qv}#{rv} in #{versions.inspect}" if best_version.nil?
    best_version  
  end
  
  def initialize(name, constraint)
    @name = name
    @constraint = self.class.parse_constraint(constraint)
  end
  
  def full_spec
    @full_spec ||= [name, @constraint].flatten
  end
  
  def name
    @name
  end
  
  def constraint
    @constraint
  end
  
  def best_version(options = {})
    options = { :pre => false }.merge(options)
    
    if options[:pre]    
      @best_version_with_pre ||= self.class.select_version(
        self.class.dependencies_to_version_array(
          self.class.get_all_dependencies(name)),
       constraint, options)
     else
      @best_version_without_pre ||= self.class.select_version(
        self.class.dependencies_to_version_array(
          self.class.get_all_dependencies(name)),
       constraint, options) 
     end
  end
  
  def dependencies    
    @dependencies ||= self.class.get_dependencies(name, best_version)
  end
  
  #TODO return sucess or fail
  def download(options = {}, &block)
    options = { :recursive => false, :install => false, :clean => false, :cache => {} }.merge(options)
    
    is_ok = false
    options[:cache][:depth] ||= 1
    
    if options[:clean]
      Dir.glob('*.gem').each do|f|
        #TODO
        puts f
        #File.delete f
      end
      #ensure it won't be exec recursively
      options[:clean] = false
    end
    
    if options[:recursive]
      
      puts "#{' ' * options[:cache][:depth]}Resolving dependencies for #{name}-#{best_version}..."
      
      options[:cache][:depth] += 1
            
      dependencies.each do |dep|
        raise "dep.size != 2" if dep.size != 2
        
        puts "#{' ' * options[:cache][:depth]}Dependency #{dep[0]}, #{dep[1]}:"
        # try to use the vg in the cache first
        vg = options[:cache][[dep[0], dep[1]]]
        # if cache isn't hit, create a new vg         
        vg = VersionedGem.new(dep[0], dep[1]) if vg.nil?           
        vg.download(options, &block) 
        # write into cache
        options[:cache][[dep[0], dep[1]]] = vg
      end
      
      options[:cache][:depth] -= 1
    end
    
    unless block_given?
      
      file = "#{name}-#{best_version}.gem"
      #avoid dup
      unless File.exists?(file)
        puts "#{' ' * options[:cache][:depth]}Downloading #{file}..."
        puts `curl --location http://rubygems.org/downloads/#{name}-#{best_version}.gem -o #{file}`
        is_ok = true if $?
      else
        puts "#{' ' * options[:cache][:depth]}Using #{file}..."
        is_ok = true
      end
      
      if options[:install]      
        puts "#{' ' * options[:cache][:depth]}Installing #{file}..."
        puts `gem install -l #{file}`
        if $?
          is_ok = true
        else
          puts "#{' ' * options[:cache][:depth]}Install #{file} failed."
        end
      end
    else
      yield "http://rubygems.org/downloads/#{name}-#{best_version}.gem", "#{name}-#{best_version}.gem"
    end
  end
end