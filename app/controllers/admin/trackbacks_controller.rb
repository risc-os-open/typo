class Admin::TrackbacksController < Admin::BaseController

  before_action :get_article

  def index
    list
    render_action 'list'
  end

  def list
    @trackbacks = @article.trackbacks.order(id: :desc)
  end

  def show
    @trackback = @article.trackbacks.find(params[:id])
  end

  def new
    @trackback = @article.trackbacks.build(params[:trackback])
  end

  def create
    self.new() # Initialise @trackback

    if @trackback.save
      flash[:notice] = 'Trackback was successfully created.'
      redirect_to :action => 'show', :id => @trackback.id
    else
      render :new
    end
  end

  def edit
    @trackback = @article.trackbacks.find(params[:id])
    @trackback.attributes = params[:trackback]
  end

  def update
    self.edit() # Initialise @trackback

    if @trackback.save
      flash[:notice] = 'Trackback was successfully updated.'
      redirect_to :action => 'show', :id => @trackback.id
    else
      render :edit
    end
  end

  def destroy
    @trackback = @article.trackbacks.find(params[:id])
    if request.post?
      @trackback.destroy
      redirect_to :action => 'list'
    end
  end

  private

    def get_article
      @article = Article.find(params[:article_id])
      redirect_to(admin_root_path()) if @article.nil?
    end

end
