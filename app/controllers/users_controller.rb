class UsersController < ApplicationController
  # before_filter :require_user, :only => [:index, :show, :edit, :update]
  # before_filter :require_admin, :only => [:new]
  
  before_filter :find_user, :only => [:show, :edit, :update]

  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml  => @users }
      format.json { render :json => @users }
    end
  end
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:success] = "Registration successful"
      redirect_back_or_default user_path( @user )
    else
      render :action => :new
    end
  end

  def update
    if @user.update_attributes(params[:user])
      flash[:success] = "Update successful"
      redirect_to user_path( @user )
    else
      render :action => :edit
    end
  end

  def show
  end

  def edit
  end
  
  private
    def find_user # makes our views "cleaner" and more consistent
      if params[:id]
        if @current_user.is_admin
          @user = User.find(params[:id])
        else
          flash[:error] = "Access restricted - you need to be admin"
          redirect_to root_url
        end
      else
        @user = current_user
      end
    end
end