class Admin::CommentsController < Admin::BaseController

  before_action :get_article

  def index
    list
    render action: 'list'
  end

  def list
    @comments = @article.comments.order(id: :desc)
  end

  def show
    @comment = @article.comments.find(params[:id])
  end

  def new
    @comment = @article.comments.build(params[:comment])
  end

  def create
    self.new() # Initialise @comment

    if @comment.save
      # We should probably wave a spam filter over this, but for now, just mark it as published.
      @comment.mark_as_ham!
      flash[:notice] = 'Comment was successfully created.'
      redirect_to :action => 'show', :id => @comment.id
    else
      render :new
    end
  end

  def edit
    @comment = @article.comments.find(params[:id])
    @comment.attributes = params[:comment]
  end

  def update
    self.edit() # Initialise @comment

    if @comment.save
      flash[:notice] = 'Comment was successfully updated.'
      redirect_to :action => 'show', :id => @comment.id
    else
      render :edit
    end
  end

  def destroy
    @comment = @article.comments.find(params[:id])
    if request.post?
      @comment.destroy
      redirect_to :action => 'list'
    end
  end

  private

    def get_article
      @article = Article.find(params[:article_id])
      redirect_to(admin_root_path()) if @article.nil?
    end

end
