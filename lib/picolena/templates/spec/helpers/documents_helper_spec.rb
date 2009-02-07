require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentsHelper do
  PlainTextExtractor.supported_extensions.each{|ext|
    it "should have an icon for .#{ext} filetype" do
      Picolena::FiletypeToIconSymbol[ext].should_not be_nil
    end
  }

  it "should not raise for filetypes without any associated icon when calling icon_for" do
     Picolena::FiletypeToIconSymbol[:xyz].should be_nil
     document=Spec::Mocks::Mock.new('Document', :ext_as_sym => :xyz, :icon_path => nil)
     lambda {helper.icon_for(document)}.should_not raise_error
  end

  it "should not raise for files without content when calling highlighted_cache" do
     document=Spec::Mocks::Mock.new('Document', :highlighted_cache => "\f")
     lambda {helper.highlighted_cache(document, 'some_query')}.should_not raise_error
  end
end
