require File.expand_path('../../versioned_gem', __FILE__)

describe VersionedGem do
  
      # =  Equals version
  # != Not equal to version
  # >  Greater than version
  # <  Less than version
  # >= Greater than or equal to
  # <= Less than or equal to
  # ~> Approximately greater than 
     # (see "Pessimistic Version Constraint" below)
  context '(classs)' do
    it 'should parse empty constraint' do
      VersionedGem.parse_constraint(nil).should == ['>', '0.0.0']
      VersionedGem.parse_constraint('').should == ['>', '0.0.0']
    end
    
    it 'should parse contraint like > 0 or >= 0' do
      VersionedGem.parse_constraint('> 0').should == ['>', '0.0.0']
      VersionedGem.parse_constraint('>= 0').should == ['>', '0.0.0']
    end
    
    it 'should parse `2-digit version`' do
      VersionedGem.parse_constraint('2.1').should == ['=', '2.1']
    end

    ['=', '!=', '>', '<', '>=', '<=', '~>'].each do |q|
      it "should parse `#{q} 2-digit version`" do
        VersionedGem.parse_constraint("#{q} 2.1").should == [q, '2.1']
      end
    end
    
    it 'should parse `3-digit version`' do
      VersionedGem.parse_constraint('2.1.1').should == ['=', '2.1.1']
    end
    
    ['=', '!=', '>', '<', '>=', '<=', '~>'].each do |q|
      it "should parse `#{q} 3-digit version`" do
        VersionedGem.parse_constraint("#{q} 2.1.1").should == [q, '2.1.1']
      end
    end
    
    it 'should parse `beta-like version`' do
      VersionedGem.parse_constraint('2.1.1beta2').should == ['=', '2.1.1beta2']
      VersionedGem.parse_constraint('2.1.1RC2').should == ['=', '2.1.1RC2']
    end
    
    it 'should tollerent not quite semantic versions' do
      VersionedGem.parse_constraint('2.1.1.beta2').should == ['=', '2.1.1.beta2']
      VersionedGem.parse_constraint('2.1.1.rc.2').should == ['=', '2.1.1.rc.2']
      VersionedGem.parse_constraint('2.1.1.rc-2').should == ['=', '2.1.1.rc-2']
    end
    
    ['=', '!=', '>', '<', '>=', '<=', '~>'].each do |q|
      it "should parse `#{q} beta-like version`" do
        VersionedGem.parse_constraint("#{q} 2.1.1beta2").should == [q, '2.1.1beta2']
      end
    end
    
    it "should reject invalid constraints" do
      lambda { VersionedGem.parse_constraint("> 2") }.should raise_error
      lambda { VersionedGem.parse_constraint("= q") }.should raise_error
    end
    
    it "should return the upper bound of a version in the sense of ~>" do
      VersionedGem.upper_bound('2.1').should == '3.0'
      VersionedGem.upper_bound('2.1.0').should == '2.2.0'
    end
    
    it "should select the best version based on the version constraint" do
      #'=', '!=', '>', '<', '>=', '<=', '~>'
      
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['=', '2.1.1']).
            should == '2.1.1'
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['!=', '2.1.1']).
            should == '3.0.0'
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['!=', '3.0.0']).
            should == '2.2.0'
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['>', '2.1.1']).
            should == '3.0.0'
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['>=', '2.1.1']).
            should == '3.0.0'
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['>=', '3.0.0']).
            should == '3.0.0'
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['<', '2.1.1']).
            should == '2.1.0'
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['<=', '2.1.1']).
            should == '2.1.1'
    end
    
    it "should select the best version when it's like xx.x.x, x.xx.x or x.x.xx" do
      #'=', '!=', '>', '<', '>=', '<=', '~>'
      VersionedGem.select_version(
            ['2.2.3', '2.2.10'], ['>', '2.2.2']).
            should == '2.2.10'
      VersionedGem.select_version(
            ['2.3.0', '2.10.0'], ['>', '2.2.0']).
            should == '2.10.0'
      VersionedGem.select_version(
            ['3.0.0', '10.0.0'], ['>', '2.0.0']).
            should == '10.0.0'
    end
    
    it "should select the best version when it's like x.x.xbeta1" do
      #'=', '!=', '>', '<', '>=', '<=', '~>'
      VersionedGem.select_version(
            ['2.2.3', '2.2.3beta'], ['>', '2.2.2']).
            should == '2.2.3'
    end
    
    it "should accept :pre => true/false as option to select the best version with default to false" do
      VersionedGem.select_version(
            ['2.2.3', '2.2.4beta'], ['>', '2.2.2']).
            should == '2.2.3'
      VersionedGem.select_version(
            ['2.2.3', '2.2.4beta'], ['>', '2.2.2'], :pre => false).
            should == '2.2.3'
      VersionedGem.select_version(
            ['2.2.3', '2.2.4beta'], ['>', '2.2.2'], :pre => true).
            should == '2.2.4beta'            
    end
    
    it "should select the best version based on the pessimistic version constraint" do
      #VersionedGem.should_receive(:upper_bound).with('2.1.0') #.and_return('2.2.0')  
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['~>', '2.1.0']).
            should == '2.1.1'
      #VersionedGem.should_receive(:upper_bound).with('2.1') #.and_return('3.0')  
      VersionedGem.select_version(
            ['2.1.0', '2.1.1', '2.2.0', '3.0.0'], ['~>', '2.1']).
            should == '2.2.0'       
    end
    
    it "should convert dependencies_to_version_hash" do
      deps = []
      ['3.0.1', '3.0.2', '3.0.3'].each do |ver|
        deps << {:platform=>"ruby",
                  :dependencies=>
                   [["bundler", "~> 1.0"],
                    ["railties", "= #{ver}"],
                    ["actionmailer", "= #{ver}"],
                    ["activeresource", "= #{ver}"],
                    ["activerecord", "= #{ver}"],
                    ["actionpack", "= #{ver}"],
                    ["activesupport", "= #{ver}"]],
                  :name=>"rails",
                  :number=>ver}
      end
      
      vers = VersionedGem.dependencies_to_version_hash(deps)
      ['3.0.1', '3.0.2', '3.0.3'].each do |ver|
        vers.should have_key(ver)
        vers[ver].should == 
            {:platform=>"ruby",
              :dependencies=>
               [["bundler", "~> 1.0"],
                ["railties", "= #{ver}"],
                ["actionmailer", "= #{ver}"],
                ["activeresource", "= #{ver}"],
                ["activerecord", "= #{ver}"],
                ["actionpack", "= #{ver}"],
                ["activesupport", "= #{ver}"]],
              :name=>"rails",
              :number=>ver}
      end
    end
    
    it "should convert dependencies_to_version_array" do
      deps = []
      ['3.0.1', '3.0.2', '3.0.3'].each do |ver|
        deps << {:platform=>"ruby",
                  :dependencies=>
                   [["bundler", "~> 1.0"],
                    ["railties", "= #{ver}"],
                    ["actionmailer", "= #{ver}"],
                    ["activeresource", "= #{ver}"],
                    ["activerecord", "= #{ver}"],
                    ["actionpack", "= #{ver}"],
                    ["activesupport", "= #{ver}"]],
                  :name=>"rails",
                  :number=>ver}
      end
      
      VersionedGem.dependencies_to_version_array(deps).should_not ==
        [SemVer.new('3.0.1'), SemVer.new('3.0.2'), SemVer.new('3.0.3')]
      VersionedGem.dependencies_to_version_array(deps).should ==
        ['3.0.1', '3.0.2', '3.0.3']  
    end
    
    it "should get all dependencies of all_versions of a gem from rubygem.org api" do
      deps = VersionedGem.get_all_dependencies('rails')
      
      deps.should_not be_nil
      deps.should be_an_instance_of(Array)      
      deps.each do |dep|
        dep.should be_an_instance_of(Hash)
        [:name, :number, :platform, :dependencies].each do |key|
          dep.should have_key(key)
        end
        
        dep[:name].should == 'rails'
        dep[:dependencies].should be_an_instance_of(Array)
        dep[:dependencies].each do |d|
          d.should be_an_instance_of(Array)
          d.size.should == 2
          
          lambda {VersionedGem.parse_constraint(d[1])}.should_not raise_error
          
          lambda { VersionedGem.new(d[0], d[1]) }.should_not raise_error
        end
        
        #TODO more specs here
        
      end      
    end
    
    it "should get all dependencies of a specified version of a gem from rubygem.org api" do
      deps = VersionedGem.get_dependencies('rails', '2.1.0')
      deps.should_not be_nil
      deps.should be_an_instance_of(Array) 
               
      deps.each do |d|
        d.should be_an_instance_of(Array)
        d.size.should == 2
      end
    end
    
    it "should not get all dependencies of a non-existed version of a gem from rubygem.org api" do
      lambda {VersionedGem.get_dependencies('rails', '100.1.1')}.should raise_error
    end
    
    it "should get all dependencies of the first specified version of a gem from rubygem.org api" do
      VersionedGem.should_receive(:get_all_dependencies).with('rails').and_return(
      [{:platform=>"ruby", :dependencies=> [ 'xxx' ], :name=>"rails", :number=>"3.0.3"}, 
       {:platform=>"ruby", :dependencies=> [ 'xxxxx' ], :name=>"rails", :number=>"3.0.3"}] )
       
      VersionedGem.get_dependencies('rails', '3.0.3').should == ['xxx'] 
    end

  end
  
  context '(instance)' do  
    before do
      @vg = VersionedGem.new 'minitest', '~> 2.1'
      @vg2 = VersionedGem.new 'activesupport', '3.1.1'
    end
    
    it "should accept (name, constraint) and a block to construct" do  
      @vg.should_not be_nil
    end
    
    it "should be able to return gem constraint specifier" do
      @vg.full_spec.should == ['minitest', '~>', '2.1']
    end
    
    it "should return gem name" do 
      @vg.name.should == 'minitest'
    end
    
    it "should return gem constraint" do 
      @vg.constraint.should == ['~>', '2.1']
    end
    
    it "should really determine the best gem version" do
      VersionedGem.should_receive(:get_all_dependencies).with('minitest').
          and_return({"stub" => "stub!"});
      VersionedGem.should_receive(:dependencies_to_version_array).with({"stub" => "stub!"}).
          and_return(['2.0.0', '2.1.0', '2.7.0', '2.8.0rc1', '3.0.0']);
      @vg.best_version.should == '2.7.0'
    end
    
    it "should really determine the best gem version with :pre => true" do
      VersionedGem.should_receive(:get_all_dependencies).with('minitest').
          and_return({"stub" => "stub!"});
      VersionedGem.should_receive(:dependencies_to_version_array).with({"stub" => "stub!"}).
          and_return(['2.0.0', '2.1.0', '2.7.0', '2.8.0rc1', '3.0.0']);
      @vg.best_version(:pre => true).should == '2.8.0rc1'
    end

    it "should really determine the best gem version" do
      vg = VersionedGem.new('rack-mount', '~> 0.6.14')
      bv = SemVer.new(vg.best_version)
      bv.should >= SemVer.new('0.6.14')
      bv.should < SemVer.new('0.7.0')
    end
    
    it "should return dependencies"  do
      @vg.should_receive(:best_version).
          and_return('2.7.0');
      VersionedGem.should_receive(:get_dependencies).with('minitest', '2.7.0').
          and_return([{"stub" => "stub!"}]);
      @vg.dependencies.should == [{"stub" => "stub!"}]
    end
    
    it "should return real dependencies"  do
      @vg2.dependencies.should == [['multi_json', '~> 1.0']]
    end
    
    it "should download not recursively" do
      @vg2.download do |url, file_name| 
          #clean up
          file = File.expand_path("../#{@vg2.name}-#{@vg2.best_version}.gem", __FILE__)          
          FileUtils.remove_file file if File.exists?(file)
          
          File.exists?(file).should == false 
          url.should == 'http://rubygems.org/downloads/activesupport-3.1.1.gem'
          file_name.should == 'activesupport-3.1.1.gem'   
          `curl --location #{url} -o #{file}`
          File.exists?(file).should == true 
      end      
    end
    
    it "should download recursively" do
      count = 0      
      @vg2.download(:recursive => true) do |url, file_name|
        if  count == 0
          #clean up
          file = File.expand_path("../multi_json-1.0.3.gem", __FILE__)
          FileUtils.remove_file file if File.exists?(file)
          
          url.should == 'http://rubygems.org/downloads/multi_json-1.0.3.gem'
          file_name.should == 'multi_json-1.0.3.gem'
          File.exists?(file).should == false 
          `curl --location #{url} -o #{file}`
          File.exists?(file).should == true
          count+=1 
        else
          #clean up
          file = File.expand_path("../activesupport-3.1.1.gem", __FILE__)
          FileUtils.remove_file file if File.exists?(file)
          
          url.should == 'http://rubygems.org/downloads/activesupport-3.1.1.gem'
          file_name.should == 'activesupport-3.1.1.gem'
          File.exists?(file).should == false 
          `curl --location #{url} -o #{file}`
          File.exists?(file).should == true 
          count+=1
        end
      end
      
      count.should == 2 
      
      #No clean up for the time being, maybe later    
    end
  end  
end