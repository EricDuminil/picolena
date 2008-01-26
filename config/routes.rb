ActionController::Routing::Routes.draw do |map|
  map.resources :documents, :collection=>{:check_query=>:post}, :member=>{:download=>:get}
  map.connect 'documents/:id', :controller=>'documents', :action=>'show', :id => /.*/
  map.connect 'access_denied', :controller=> 'application', :action => 'access_denied'
  map.connect "*anything", :controller=>'application', :action => 'unknown_request'
end
