class SemVer
  include Comparable
  
  attr_reader :major, :minor, :patch, :special
  
  def initialize(version)
    parse(version)
  end
  
  def <=>(another)
    return major <=> another.major unless major == another.major
    return minor <=> another.minor unless minor == another.minor
    return patch <=> another.patch unless patch == another.patch
    
    #an empty special is greater than an unempty one
    unless special == another.special
      return 1 if special == ''
      return -1 if another.special == ''
    end
    
    return special <=> another.special 
  end
  
  def to_s
    "#{major}.#{minor}.#{patch}#{special}"
  end
  
  def pre?
    @special != ''
  end
  
  private
  
  def parse(version)
    matched = version.match /^\s*((\d+)\.(\d+)(\.(\d+))?(\.?[A-Za-z0-9][0-9A-Za-z\-.]*)?)\s*$/
    raise "Invalid semantic version [#{version}]" if matched.nil?
    
    @major, @minor, @patch, @special = matched[2], matched[3], matched[5], matched[6] 
    @major = @major.to_i
    @minor = @minor.to_i
    @patch ||= 0
    @patch = @patch.to_i
    @special ||= ''
  end
end