require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController do
  it "should give 403 when denying access" do
    get 'access_denied'
    response.headers["Status"].should == "403 Forbidden"
  end
  
  it "should flash with a wrong request" do
    get 'unknown_request'
    response.should be_redirect
    response.should redirect_to(documents_url)
    flash[:warning].should == "Unknown URL"
  end
end