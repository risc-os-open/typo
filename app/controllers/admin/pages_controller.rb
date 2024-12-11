require 'base64'

class Admin::PagesController < Admin::BaseController
  def index
    list
    render_action 'list'
  end

  def list
    @pages = Page.all(order: "id DESC")
    @page = Page.new(params[:page])
    @page.text_filter ||= this_blog.text_filter
  end

  def show
    @page = Page.find(params[:id])
  end

  def new
    @page = Page.new(params[:page])
    @page.user_id = session[:user].id
    @page.text_filter ||= this_blog.text_filter
  end

  def create
    self.new() # Initialise @page

    if @page.save
      flash[:notice] = 'Page was successfully created.'
      redirect_to :action => 'show', :id => @page.id
    else
      render :new
    end
  end

  def edit
    @page = Page.find(params[:id])
    @page.attributes = params[:page]
  end

  def update
    self.edit() # Initialise @page

    if @page.save
      flash[:notice] = 'Page was successfully updated.'
      redirect_to :action => 'show', :id => @page.id
    else
      render :edit
    end
  end

  def destroy
    @page = Page.find(params[:id])
    if request.post?
      @page.destroy
      redirect_to :action => 'list'
    end
  end

  def preview
    headers["Content-Type"] = "text/html; charset=utf-8"
    @page = this_blog.pages.build(params[:page])
    data = render_to_string(:layout => "minimal")
    data = Base64.encode64(data).gsub("\n", '')
    data = "data:text/html;charset=utf-8;base64,#{data}"
    render :text => data
  end
end
