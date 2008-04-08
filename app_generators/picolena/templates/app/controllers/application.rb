class ApplicationController < ActionController::Base  
  session :disabled => true
  before_filter :should_only_be_available_for_white_list_IPs, :except=> :access_denied
  
  # In case of an unknown IP address
  def access_denied
    render :text=>'Access denied', :status => 403
  end
  
  # In case route hasn't been recognised
  def unknown_request
    flash[:warning]="Unknown URL"
    redirect_to documents_url
  end
  
  private
  
  def should_only_be_available_for_white_list_IPs
    unless request.remote_ip =~ WhiteListIPs
      redirect_to :controller => 'application', :action=>'access_denied'
      return false
    end
  end
end