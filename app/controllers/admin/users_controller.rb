class Admin::UsersController < Admin::BaseController

  def index
    list
    render_action 'list'
  end

  def list
    @users = User.all
  end

  def show
    @user = User.find(params[:id], :include => [ :articles ])
    @articles = @user.articles
  end

  def new
    @user = User.new(params[:user])
  end

  def create
    self.new() # Initialise @user

    if @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'list'
    else
      render :new
    end
  end

  def edit
    @user = User.find(params[:id])
    @user.attributes = params[:user]
  end

  def update
    self.edit() # Initialise @user

    if @user.save
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user.id
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])
    if request.post?
      @user.destroy if User.count > 1
      redirect_to :action => 'list'
    end
  end

end
