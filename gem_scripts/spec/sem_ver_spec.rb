require File.expand_path('../../sem_ver', __FILE__)


describe SemVer do
  before do
    @v = SemVer.new '3.0.10rc1'
  end
  
  it 'should intialize correctly' do
    @v.should_not be_nil
  end
  
  it 'should parse version correctly' do
    @v.major.should == 3
    @v.minor.should == 0
    @v.patch.should == 10
    @v.special.should == 'rc1'
  end
  
  it "should has #to_s" do
    @v.to_s.should == '3.0.10rc1'
    SemVer.new('3.0.11').to_s.should == '3.0.11'
    SemVer.new('3.0').to_s.should == '3.0.0'
  end
  
  it "should tell whether it's a pre-release version" do 
    SemVer.new('3.0.11').should_not be_pre
    SemVer.new('3.0.11rc1').should be_pre
  end
  
  it 'should compare versions correctly' do    
    @v.should == @v
    SemVer.new('3.0.10').should == SemVer.new('3.0.10')
    
    SemVer.new('3.0.10rc1').should < SemVer.new('3.0.10')
    SemVer.new('3.0.10').should > SemVer.new('3.0.10rc1')
    
    SemVer.new('3.0.10rc1').should < SemVer.new('3.0.10rc2')
    SemVer.new('3.0.10rc2').should > SemVer.new('3.0.10rc1')
    
    SemVer.new('3.0.10').should < SemVer.new('3.0.11')
    SemVer.new('3.0.11').should > SemVer.new('3.0.10')
    
    SemVer.new('3.0.10').should < SemVer.new('3.1.3')
    SemVer.new('3.1.3').should > SemVer.new('3.0.10')
    
    SemVer.new('3.0.10').should < SemVer.new('4.0.0')
    SemVer.new('4.0.0').should > SemVer.new('3.0.10')
  end
end