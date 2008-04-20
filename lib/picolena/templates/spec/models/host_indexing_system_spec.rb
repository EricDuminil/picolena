require File.dirname(__FILE__) + '/../spec_helper'

describe "Host indexing system" do
 PlainTextExtractor.dependencies.each do |dependency|
    it "should have #{dependency} installed" do
       IO.popen("which #{dependency}"){|i| i.read.should_not be_empty}
    end
  end
  
  it "should have a language guesser installed" do
    PlainTextExtractor.language_guesser.should_not be_nil
  end
  
  it "should know which IP addresses are allowed (config/custom/white_list_ip.yml)" do
    File.should be_readable('config/custom/white_list_ip.yml')
  end
  
  it "should know which directories are to be indexed (config/custom/indexed_directories.yml)" do
    File.should be_readable('config/custom/indexed_directories.yml')
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
end
