class UserSessionsController < ApplicationController
  
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:destroy, :forgot_password, :change_password]

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to courses_url
      return false
    end
  end

  def new
    @user_session = UserSession.new
    render layout: "authentication"
  end

  # Logs a user in
  def create
    @user_session = UserSession.new(params[:user_session])

    # make cookies secure
    cookies.signed[:secure_user_id] = {secure: true, value: "secure_key"}

    if @user_session.save
      flash[:notice] = "Login successful!"
      #redirect_back_or_default dashboard_url(@current_user)
      redirect_back_or_default courses_url
    else
      if Ldap.valid?(params[:user_session][:netid], params[:user_session][:password])
        user_cred = Ldap.getuser(params[:user_session][:netid], params[:user_session][:password])
        @user = User.new(user_cred)
        @user.add_role :student

        if @user.save
          @user_session = UserSession.new(params[:user_session])
          if @user_session.save
            redirect_to setting_url(@user) and return
          else
            flash[:notice] = "There was a problem logging you in."
            render :layout => "authentication", :action => :new
          end
        else
          flash[:notice] = "There was a problem creating your account."
          render :layout => "authentication", :action => :new    
        end
      else
        flash[:notice] = "There was a problem validating your netID."
        render :layout => "authentication", :action => :new 
      end      
    end
  end

  # Logs a user out
  def destroy
    cookies.delete(:secure_user_id)
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end

