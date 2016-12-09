class UsersController < ApplicationController
  before_filter :require_user, :only => [:show, :dashboard, :index, :update, :settings, :change_password]
  before_filter :require_admin, :only => [:edit, :destroy]

  def require_admin
    if not current_user.has_role? :admin
      flash[:notice] = "You may not edit other accounts."
      redirect_to dashboard_url
    end
  end

  # Displays the new user form
  def new
    @user = User.new
    render layout: "authentication"
  end

  # Creates a new user and saved to the database
  def create
    @user = User.new(user_params)
    @user.add_role :student

    if @user.save
      flash[:notice] = "Your account has been created."
      redirect_to dashboard_url
    else
      flash[:notice] = "There was a problem creating your account."
      render :action => :new, :layout => "authentication"
    end
  end

  # Displays info about a user
  def show
    @user = User.find(params[:id])
  end

  # Main page displayed after logging in
  def dashboard
    @user = current_user
  end

  # Lists all users
  def index
    redirect_to dashboard_url unless current_user.has_role? :admin
    @users = User.all
  end

  # Displays the form to edit a user
  def edit
    @user = User.find(params[:id])
  end

  # Displays the settings page for the currently logged in user
  def settings
    @user = current_user
  end

  # Displays the change password form for the currently logged in user
  def change_password
    @user = current_user
  end

  # Persists changes to a user to the database
  def update
    if params.has_key? :id
      @user = User.find(params[:id])
    else
      @user = current_user
    end

    if params[:user].has_key? :roles
      User::ROLES.each do |role|
        if params[:user][:roles].include? role
          @user.add_role role 
        else
          @user.remove_role role
        end
      end
    end

    if @user.update_attributes(user_params)
      flash[:notice] = "Account updated!"
      redirect_to :users
    end
  end

  # Deletes a user
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:notice] = "User successfully deleted"

    redirect_to :back
  end

  private
  def user_params
    params.require(:user).permit(:netid, :first_name, :last_name, :email, :commit)
  end
end
