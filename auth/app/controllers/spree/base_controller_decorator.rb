Spree::BaseController.class_eval do
  before_filter :check_guest

  include Spree::AuthUser

  # graceful error handling for cancan authorization exceptions
  rescue_from CanCan::AccessDenied do |exception|
    return unauthorized
  end

  private
  # authorize the user as a guest if the have a valid token
  def check_guest
    session[:guest_token] ||= params[:token]
  end

  #def current_user
  #  return @current_user if defined?(@current_user)
  #  @current_user = current_user_session && current_user_session.user
  #end

  # Redirect as appropriate when an access request fails.  The default action is to redirect to the login screen.
  # Override this method in your controllers if you want to have special behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might simply close itself.
  def unauthorized
    respond_to do |format|
      format.html do
        if current_user
          flash.now[:error] = I18n.t(:authorization_failure)
          render 'shared/unauthorized', :layout => 'spree_application'
        else
          store_location
          redirect_to login_path and return
        end
      end
      format.xml do
        request_http_basic_authentication 'Web Password'
      end
      format.json do
        # NOTE: We really want to return 301 error code but this causes issues with Devise and Warden.  Just return the phony 418
        # since we're not going to waste our time sorting this out.  Honestly, who really gives a fuck?  Unauthorized says it all.
        render :text => "Not Authorized \n", :status => 418
      end
    end
  end

  def store_location
    # disallow return to login, logout, signup pages
    disallowed_urls = [signup_url, login_url, destroy_user_session_path]
    disallowed_urls.map!{|url| url[/\/\w+$/]}
    unless disallowed_urls.include?(request.fullpath)
      session[:return_to] = request.fullpath
    end
  end

end