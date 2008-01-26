require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentsHelper do
  
  #Delete this example and add some real ones or delete this file
  it "should include the DocumentsHelper" do
    included_modules = self.metaclass.send :included_modules
    included_modules.should include(DocumentsHelper)
  end
  
  it "shouldn't raise if matching not in content field"
  
end
