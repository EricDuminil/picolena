require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentsHelper do  
  it "shouldn't raise if matching not in content field"

  PlainText.supported_extensions.each{|ext|
    it "should have an icon for .#{ext} filetype" do 
      icon_for(ext.to_s).should_not be_nil
    end
  }
end
