require File.dirname(__FILE__) + '/../spec_helper'

def redefine_ruby_platform(new_platform)
  Object.send(:remove_const, :RUBY_PLATFORM)
  Object.const_set(:RUBY_PLATFORM,new_platform)
end

describe "Host indexing system" do
  before(:all) do
    @original_platform = RUBY_PLATFORM
  end
 
  PlainTextExtractor.dependencies.each do |dependency|
    it "should have #{dependency} installed" do
       dependency.should be_installed
    end
  end

  it "should have a language guesser installed" do
    PlainTextExtractor.language_guesser.should_not be_nil
  end

  it "should know which IP addresses are allowed (config/custom/white_list_ip.yml)" do
    File.should be_readable('config/custom/white_list_ip.yml')
    ip_conf=YAML.load_file('config/custom/white_list_ip.yml')
    ip_conf.class.should == Hash
    ip_conf['Allow'].should_not be_nil
  end

  it "should know which directories are to be indexed (config/custom/indexed_directories.yml)" do
    File.should be_readable('config/custom/indexed_directories.yml')
    dirs_conf=YAML.load_file('config/custom/indexed_directories.yml')
    dirs_conf.class.should == Hash
    %w(development test production).all?{|env|
      dirs_conf[env].should_not be_nil
    }
  end

  it "should know on which platform it is running" do
    redefine_ruby_platform('i486-linux')
    ruby_platform_symbol.should == :linux

    redefine_ruby_platform('universal-darwin9.0')
    ruby_platform_symbol.should == :mac_os

    redefine_ruby_platform('mswin32')
    ruby_platform_symbol.should == :windows
  end

  it "should be able to calculate base26 hash from strings" do
    "test_dirs/indexed/010/decrepito.pdf".base26_hash(5).should == "rails"
    "test_dirs/indexed/migrations/000_restreins.rb".base26_hash(5).should == "ricou"
    # it would probably take ages to find a string whose hash == "picolena" :(
    "test_dirs/indexed/1148/plots.odt".base26_hash(8).should == "picolehn"
    "whatever.pdf".base26_hash(10).should == "bbuxhynait"
  end

  it "should not use too small a hash for Document#probably_unique_id" do
    Picolena::HashLength.should_not < 10
  end

  after(:all) do
    redefine_ruby_platform(@original_platform)
  end
end
