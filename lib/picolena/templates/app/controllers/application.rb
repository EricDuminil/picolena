# ApplicationController just checks every incoming request according to the remote IP address.
#
# The request is sent to DocumentsController only if the IP is included in the white list.
# Otherwise, it returns "Access denied" 403.

class ApplicationController < ActionController::Base  
  session :disabled => true
  before_filter :should_only_be_available_for_white_list_IPs, :except=> :access_denied
  
  # Returns 403 status in case of an unknown remote IP address
  def access_denied
    render :text=>"Access denied", :status => 403
  end
  
  # Redirects to documents_url in case route hasn't been recognised
  def unknown_request
    flash[:warning]="Unknown URL"
    redirect_to documents_url
  end
  
  private
  
  # Tries to match remote IP address with the white list defined in config/custom/white_list_ip.yml
  # Redirects to :access_denied if the remote IP is not white listed.
  def should_only_be_available_for_white_list_IPs
    unless request.remote_ip =~ Picolena::WhiteListIPs
      redirect_to :controller => 'application', :action=>'access_denied'
      return false
    end
  end
end
