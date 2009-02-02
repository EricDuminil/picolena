require File.dirname(__FILE__) + '/../spec_helper'

describe "IndexedDirectories" do
  it "should be defined" do
    lambda {Picolena::IndexedDirectories}.should_not raise_error(NameError)
  end

  it "should not be empty" do
    Picolena::IndexedDirectories.should_not be_empty
  end

  it "should only contain existing directories" do
    Picolena::IndexedDirectories.keys.all?{|dir|
      File.should be_directory(dir)
    }
  end

  it "should define which files are to be ignored" do
    Picolena::ToIgnore.should be_kind_of(Regexp)
  end
end
