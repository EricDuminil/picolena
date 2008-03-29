require 'rubygems'
require 'spec'

describe "Host indexing system" do
  %w{ferret paginator haml rubyzip}.each  do |gem_name|
    it "should have #{gem_name} installed as a gem" do
      lambda {gem gem_name}.should_not raise_error
    end
  end
 
 PlainText.filter_dependencies.each do |dependency|
    it "should have #{dependency} installed" do
       IO.popen("which #{dependency}"){|i| i.read.should_not be_empty}
    end
  end
  
  it "should know which IP addresses are allowed (config/white_list_ip.yml)" do
    File.should be_readable('config/white_list_ip.yml')
  end
  
  it "should know which directories are to be indexed (config/indexed_directories.yml)" do
    File.should be_readable('config/indexed_directories.yml')
  end   
end