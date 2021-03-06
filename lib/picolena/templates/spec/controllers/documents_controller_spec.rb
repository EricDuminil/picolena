require File.dirname(__FILE__) + '/../spec_helper'

describe "DocumentsController called from unknown IP" do
  controller_name "documents"

  before(:all) do
    @backup=Picolena::WhiteListIPs
  end

  it "should deny access" do
    # Displays a warning otherwise
    Picolena.send(:remove_const, :WhiteListIPs) && Picolena::WhiteListIPs=/Something that won't match/
    get 'index'
    response.should be_redirect
    response.should redirect_to(:controller=>'application', :action=>'access_denied')
    Picolena.send(:remove_const, :WhiteListIPs) && Picolena::WhiteListIPs=/^0\.0\.0\.0/
    get 'index'
    response.should be_success
  end

  after(:all) do
    Picolena.send(:remove_const, :WhiteListIPs) && Picolena::WhiteListIPs=@backup
  end
end

describe DocumentsController do
  it "GET 'index' should be succesful" do
    get 'index'
    response.should be_success
  end

  it "POST 'check_query' should check query and redirect to show" do
    post 'check_query', {:query => 'basic test'}
    response.should be_redirect
    response.should redirect_to(document_url('basic test'))
  end

  it "POST 'check_query' should accept . and redirect to show" do
    post 'check_query', {:query => 'basic.test'}
    response.should be_redirect
    response.should redirect_to(:action=>'show', :id=>'basic.test')
  end

  it "POST 'check_query' should accept ? and redirect to show" do
    post 'check_query', {:query => '?ric'}
    response.should be_redirect
    response.should redirect_to(:action=>'show', :id=>'?ric')
  end

  it "POST 'check_query' should accept empty query but should redirect to index" do
    post 'check_query', {:query => ''}
    response.should be_redirect
    response.should redirect_to(:action=>'index')
  end

  it "GET 'show' should find corresponding docs" do
    get 'show', :id=>'forschung an fachhochschulen nachhaltige energietechnik'
    response.should be_success
    orig_assigns['matching_documents'].any?{|doc| doc.filename=="zafh.net.html"}.should be_true
  end

  it "GET 'show' should accept * in queries" do
    params_from(:get, '/documents/*ric').should == {:controller => 'documents', :action => 'show', :id => '*ric'}
    lambda{get 'show', :id=>'*ric'}.should_not raise_error
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
    orig_assigns['matching_documents'].any?{|doc| doc.matching_content.join.starts_with?("<<Éric>> Mößer")}.should be_true
  end

  it "GET 'show' should accept ? in queries" do
    params_from(:get, '/documents/%3Fric').should == {:controller => 'documents', :action => 'show', :id => '?ric'}
    lambda{get 'show', :id=>'?ric'}.should_not raise_error(ActionController::RoutingError)
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
    orig_assigns['matching_documents'].any?{|doc| doc.filename=="basic.tex"}.should be_true
  end

  it "GET 'show' should accept queries like *.pdf" do
    params_from(:get, '/documents/*.pdf').should == {:controller => 'documents', :action => 'show', :id => '*.pdf'}
    lambda{get 'show', :id=>'*.pdf'}.should_not raise_error
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
    orig_assigns['matching_documents'].to_a.size.should == Finder.new('ext:pdf').matching_documents.size
  end

  it "GET 'show' should accept . in queries" do
    params_from(:get, '/documents/basic.pdf').should == {:controller => 'documents', :action => 'show', :id => 'basic.pdf'}
    lambda{get 'show', :id=>'basic.pdf'}.should_not raise_error(ActionController::RoutingError)
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
    orig_assigns['matching_documents'].any?{|doc| doc.matching_content.join.starts_with?("just another content test in a pdf file")}.should be_true
  end

  it "GET 'show' should accept * as query" do
    params_from(:get, '/documents/*').should == {:controller => 'documents', :action => 'show', :id => '*'}
    lambda{get 'show', :id=>'*'}.should_not raise_error(ActionController::RoutingError)
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
    orig_assigns['total_hits'].should == Indexer.size
  end

  it "GET 'show' should accept combined queries" do
    get 'show', :id=>'test filetype:pdf'
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
  end

  it "GET 'show' should accept empty query but should redirect to index" do
    lambda{get 'show', :id=>''}.should_not raise_error
    response.should be_success
    orig_assigns['matching_documents'].entries.should be_empty
  end

  it "GET 'download' should be successful with correct ID" do
    get 'show', :id=>'basic.pdf'
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
    d=orig_assigns['matching_documents'].entries.first
    get 'download', :id=>d.probably_unique_id
    orig_assigns['document'].complete_path.should == d.complete_path
    response.should be_success
  end

  it "GET 'download' should be successful with correct ID and unknown MIME" do
    get 'show', :id=>'whatever.db'
    response.should be_success
    orig_assigns['matching_documents'].entries.should_not be_empty
    d=orig_assigns['matching_documents'].entries.first
    get 'download', :id=>d.probably_unique_id
    orig_assigns['document'].complete_path.should == d.complete_path
    response.should be_success
  end

  it "GET 'download' should redirect if wrong id" do
    probably_unique_id="Not a document".base26_hash
    get 'download', :id=>probably_unique_id
    response.should be_redirect
    response.should redirect_to(documents_url)
    probably_unique_id='Whatever'
    get 'download', :id=>probably_unique_id
    response.should be_redirect
    response.should redirect_to(documents_url)
  end

  it "GET 'download' should redirect if given id of an non indexed file" do
    %w(/etc/passwd /etc/shadow /etc/fstab).each{|sensitive_file|
      probably_unique_id=sensitive_file.base26_hash
      get 'download', :id=>probably_unique_id
      response.should be_redirect
      response.should redirect_to(documents_url)
    }
  end
end
