require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentsHelper do
  PlainTextExtractor.supported_extensions.each{|ext|
    it "should have an icon for .#{ext} filetype" do
      helper.icon_for(ext).should_not be_nil
    end
  }
end
