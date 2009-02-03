require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentsHelper do
  PlainTextExtractor.supported_extensions.each{|ext|
    it "should have an icon for .#{ext} filetype" do
#     document=Spec::Mocks::Mock.new('Document', :ext_as_sym => ext, :thumbnail_path=> false)
#     helper.icon_for(document).should_not be_nil
      Picolena::FiletypeToIconSymbol[ext].should_not be_nil
    end
  }
end
