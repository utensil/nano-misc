require 'rubygems'
require 'json'
require 'multi_json'


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






