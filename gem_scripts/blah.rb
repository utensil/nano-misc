require 'rubygems'
require 'json'
require 'multi_json'

# require 'rubygems'
# require 'json'
# require 'multi_json'

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


    it "should get all versions of a gem from rubygems.org api" do 
      vers = VersionedGem.get_all_versions('rails')
      vers.should_not be_nil
      vers.should be_an_instance_of(Array)
      
      vers.each do |ver|
        ver.should be_an_instance_of(Hash)
        
        ["number", "built_at", "summary", "downloads_count", "platform", "authors", "description", "prerelease"].each do |key|
          ver.should have_key(key)
        end
      end
    end

def parese_version(requirement)
  #http://docs.rubygems.org/read/chapter/16#page74
    # =  Equals version
  # != Not equal to version
  # >  Greater than version
  # <  Less than version
  # >= Greater than or equal to
  # <= Less than or equal to
  # ~> Approximately greater than 
     # (see "Pessimistic Version Constraint" below)
  
  
  requirement.match /^\s([!=><~]*)\s(\d+\.\d+(\.\d+)?([A-Za-z][0-9A-Za-z-]*)?)\s$/
end

def get_gem(name, requirement)
  
end

if __FILE__ == $0
  gem_name = ARGV[0]
  #loc = ARGV[1]
  
  gem_json = `curl http://rubygems.org/api/v1/gems/#{gem_name}.json`
  
  gem_hash = MultiJson.decode(gem_json)
  
  `curl #{gem_hash["gem_uri"]} -o #{gem_hash['name']}-#{gem_hash['version']}.gem`
  
  gem_deps = gem_hash['dependencies']['runtime']
  
  gem_deps.each do |dep|  
    get_gem dep['name'], dep['requirements']
    
  
    
    
    gem_json = `curl http://rubygems.org/api/v1/gems/#{gem_name}.json`
    gem_hash = MultiJson.decode(gem_json)
    `curl #{gem_hash["gem_uri"]} -o #{gem_hash['name']}-#{gem_hash['version']}.gem`
  end
end






