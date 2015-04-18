class UserController < ApplicationController
  before_action :find_admin, except: [:logout]

  def login_form
    if @user.has_password?
      render
    else
      session[:logged_in] = true
      redirect_to feeds_path, alert: "Logged in without a password - please set a password in account settings!"
    end
  end

  def login
    if @user.authenticate(params[:password])
      session[:logged_in] = true
      redirect_to feeds_path
    else
      flash.now[:alert] = "The password you've entered is incorrect."
      render :login_form
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(params.require(:user).permit(:password, :password_confirmation))
      redirect_to feeds_path, notice: "Your account was updated successfully."
    else
      render :edit
    end
  end

  def logout
    session[:logged_in] = false
    redirect_to login_form_user_path, notice: "You've been logged out."
  end


  private

  def find_admin
    @user = User.find_admin
  end
end
