require 'rubygems'
require 'json'
require 'multi_json'
require 'open-uri'

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
    return ['>', '0.0.0'] if gem_constraint.nil? || gem_constraint == ""       
       
    matched = gem_constraint.match /^\s*([!=><~]+)?\s*(\d+\.\d+(\.\d+\.?([A-Za-z][0-9A-Za-z\-.]*)?)?)\s*$/
    
    raise "Invalid gem constraint[#{gem_constraint}]" if matched.nil?
    
    rel = matched[1] || '='
    
    [rel, matched[2]]
  end
  
  #http://guides.rubygems.org/rubygems-org-api/
  
  # GET - /api/v1/versions/[GEM NAME].(json|xml|yaml)
  # Returns an array of gem version details like the below:
  # 
  # $ curl https://rubygems.org/api/v1/versions/coulda.json
  # 
  # [
     # {
        # "number" : "0.6.3",
        # "built_at" : "2010-12-23T05:00:00Z",
        # "summary" : "Test::Unit-based acceptance testing DSL",
        # "downloads_count" : 175,
        # "platform" : "ruby",
        # "authors" : "Evan David Light",
        # "description" : "Behaviour Driven Development derived from Cucumber but
                         # as an internal DSL with methods for reuse",
        # "prerelease" : false,
     # }
  # ]
  def self.get_all_versions(gem_name)
    versions = MultiJson.decode(open("http://rubygems.org/api/v1/versions/#{gem_name}.json"))
  end

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
    raise "#{gem_name} doesn't have a version of #{version}!" if vg_dep.nil?
    
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
  
  def self.select_version(versions, constraint)
    raise "Invalid constraint [#{constraint.to_s}]" unless constraint.instance_of?(Array) && constraint.size == 2
    raise "invalid versions [#{versions.to_s}]" unless versions.instance_of?(Array)
    
    #ensure its sorted(no need, optimize later)
    #versions.sort!
    
    qv, ver = constraint[0], constraint[1]
    
    #'=', '!=', '>', '<', '>=', '<=', '~>'
    
    best_version = case qv
    when '='
      versions.select do |v|
        v == ver
      end
    when '!='
      versions.select do |v|
        v != ver
      end
    when '>='
      versions.select do |v|
        v >= ver
      end
    when '>'
      versions.select do |v|
        v > ver
      end
    when '<='
      versions.select do |v|
        v <= ver
      end 
    when '<'
      versions.select do |v|
        v < ver
      end  
    when '~>'
      uv = self.upper_bound(ver)
      versions.select do |v|        
        v >= ver && v < uv
      end
    else
      raise "Invalid constraint symbol [#{qv}]"
    end
    
    best_version.max     
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
  
  def best_version
    @best_version ||= self.class.select_version(
      self.class.dependencies_to_version_array(
        self.class.get_all_dependencies(name)),
     constraint)
  end
  
  def dependencies
    self.class.get_dependencies(name, best_version)
  end
  
  #TODO
  def download(options = {}, &block)
    options = { :recursive => false }.merge(options)
    unless block_given?
      #avoid dup
      #TODO make it not relate to __FILE__
      file = "#{name}-#{best_version}.gem"
      unless File.exists?(file)
        `curl --location http://rubygems.org/downloads/#{name}-#{best_version}.gem -o #{file}`
      end
    else
      yield "http://rubygems.org/downloads/#{name}-#{best_version}.gem", "#{name}-#{best_version}.gem"
    end

    
    if options[:recursive]
      dependencies.each do |dep|
        raise "dep.size != 2" if dep.size != 2
        vg = VersionedGem.new(dep[0], dep[1])
        vg.download(options, &block) 
      end
    end
  end
end