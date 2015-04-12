class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :logged_in?


  private

  def logged_in?
    session[:logged_in]
  end

  def require_admin
    redirect_to login_form_user_path, alert: 'You need to log in to access this page.' unless logged_in?
  end
end
