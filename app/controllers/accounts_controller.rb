class AccountsController < ApplicationController

  before_action :verify_users, :only => [:login]

  def login
    if request.post?
      if session[:user] = User.authenticate(params[:user_login], params[:user_password])
        flash[:notice]  = "Login successful"
        cookies[:typoapp_is_admin] = "yes"
        redirect_back_or_default :controller => "admin/content", :action => "index"
      else
        flash.now[:notice]  = "Login unsuccessful"
        @login = params[:user_login]
      end
    end
  end

  def logout
    session[:user] = nil
    cookies.delete :typoapp_is_admin
  end

  def signup
    unless User.count.zero?
      redirect_to :action => 'login'
      return
    end

    @user = User.new(params[:user])

    if request.post? and @user.save
      session[:user] = User.authenticate(@user.login, params[:user][:password])
      flash[:notice]  = "Signup successful"
      redirect_to :controller => "admin/general", :action => "index"
      return
    end
  end

  private

    def verify_users
      if User.count == 0
        redirect_to :controller => "accounts", :action => "signup"
      else
        true
      end
    end

end
