require File.dirname(__FILE__) + '/../spec_helper'

describe "IndexedDirectories" do
  it "should be defined" do
    lambda {IndexedDirectories}.should_not raise_error(NameError)
  end
  
  it "should not be empty" do
    IndexedDirectories.should_not be_empty
  end
  
  it "should only contain existing directories" do
    IndexedDirectories.keys.all?{|dir|
      File.directory?(dir).should be_true
    }
  end
end