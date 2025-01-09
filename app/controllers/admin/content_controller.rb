require 'base64'

class Admin::ContentController < Admin::BaseController
  def index
    list
    render action: 'list'
  end

  def list
    setup_categories()

    scope = this_blog
      .articles
      .includes(:comments, :trackbacks)
      .order('id DESC')

    @articles_pages, @articles = pagy_with_params(scope: scope)
    @article = this_blog.articles.build(params[:article])
  end

  def show
    @article = this_blog.articles.find(params[:id])
    setup_categories()
    @resources = Resource.order(created_at: :desc)
  end

  def new;    self.new_or_edit();      end
  def edit;   self.new_or_edit();      end
  def create; self.create_or_update(); end
  def update; self.create_or_update(); end

  def destroy
    @article = this_blog.articles.find(params[:id])
    if request.post?
      @article.destroy
      redirect_to :action => 'index'
    end
  end

  def category_add; do_add_or_remove_fu; end
  alias_method :resource_add,    :category_add
  alias_method :resource_remove, :category_add

  def category_remove
    @article  = this_blog.articles.find(params[:id])
    @category = @article.categories.find(params['category_id'])
    setup_categories()
    @article.categorizations.delete(@article.categorizations.find_by(category_id: params['category_id']))
    @article.save
    render :partial => 'show_categories'
  end

  # 2024-12-18 (ADH):
  #
  # See app/views/shared/_edit.html.erb for the form observer that sets this
  # up. For whatever reasons, an iframe is used and the on-response handler
  # sets the **src attribute** to the result. That means it has to be encoded
  # as a "data" attribute. That's a... Brave choice of implementation.
  #
  def preview
    begin
      safe_params = Article.params_for_new(params, :article, required: true)

      @article = this_blog.articles.build
      @article.attributes = safe_params
      set_article_author

      data = render_to_string(layout: 'minimal')
    rescue => e
      data = e.message + "\n\n" + (e&.backtrace&.join("\n") || '')
    end

    data = Base64.encode64(data).gsub("\n", '')
    data = "data:text/html;charset=utf-8;base64,#{data}"

    render plain: data
  end

  def attachment_box_add
    render :update do |page|
      page["attachment_add_#{params[:id]}"].remove
      page.insert_html :bottom, 'attachments',
          :partial => 'admin/content/attachment',
          :locals => { :attachment_num => params[:id], :hidden => true }
      page.visual_effect(:toggle_appear, "attachment_#{params[:id]}")
    end
  end

  def attachment_save(attachment)
    begin
      Resource.create(:filename => attachment.original_filename,
                      :mime => attachment.content_type.chomp, :created_at => Time.now).write_to_disk(attachment)
    rescue => e
      Rails.logger.info(e.message)
      nil
    end
  end

  private

    attr_accessor :resources, :categories, :resource, :category

    def do_add_or_remove_fu
      attrib, action = params[:action].split('_')
      @article = this_blog.articles.find(params[:id])
      self.send("#{attrib}=", self.class.const_get(attrib.classify).find(params["#{attrib}_id"]))
      send("setup_#{attrib.pluralize}")
      @article.send(attrib.pluralize).send(real_action_for(action), send(attrib))
      @article.save
      render :partial => "show_#{attrib.pluralize}"
    end

    def real_action_for(action); { 'add' => :<<, 'remove' => :delete}[action]; end

    def new_or_edit
      self.get_or_build_article()

      self.setup_categories()
      @selected = @article.categories.collect { |c| c.id }

      safe_params = case action_name
        when 'new'
          Article.params_for_new(params, :article, required: false)
        when 'create'
          Article.params_for_new(params, :article, required: true)
        when 'edit'
          Article.params_for_edit(params, :article, required: false)
        when 'update'
          Article.params_for_edit(params, :article, required: true)
      end

      # (Sigh) Typo's older code has some very risky decisions. It's important
      # to get the ordering of the published boolean vs published_at attribute
      # setting correct, because the latter causes changes in the state
      # machine but the state that's being driven will change depending upon
      # whether or not the published boolean is set.
      #
      order_of_this_matters = safe_params.delete(:published)
      order_of_this_matters = '1' if order_of_this_matters.nil? # Default new articles to 'published'
      @article.published = ActiveModel::Type::Boolean.new.cast(order_of_this_matters)

      @article.assign_attributes(safe_params)
    end

    def create_or_update
      self.new_or_edit() # Initialise @article

      self.set_article_author()
      self.save_attachments()

      if @article.save
        self.set_article_categories()
        self.set_the_flash()
        redirect_to :action => 'show', :id => @article.id
      end
    end

    def set_the_flash
      case params[:action]
        when 'new', 'create'
          flash[:notice] = 'Article was successfully created'
        when 'edit', 'update'
          flash[:notice] = 'Article was successfully updated.'
        else
          raise "I don't know how to tidy up action: #{params[:action]}"
      end
    end

    def set_article_author
      unless @article.author.present?
        @article.author  = session.dig('user', 'login')
        @article.user_id = session.dig('user', 'id')
      end
    end

    def save_attachments
      return if params[:attachments].nil?
      params[:attachments].each do |k,v|
        a = attachment_save(v)
        @article.resources << a unless a.nil?
      end
    end

    def set_article_categories
      @article.categorizations.clear
      if params[:categories]
        Category.find(params[:categories]).each do |cat|
          @article.categories << cat
        end
      end
      @selected = params[:categories] || []
    end

    def get_or_build_article
      @article = case params[:action]
        when 'new', 'create'
          this_blog.articles.build(
            allow_comments: this_blog.default_allow_comments,
            allow_pings:    this_blog.default_allow_pings,
            published:      true
          )
        when 'edit', 'update'
          this_blog.articles.find(params[:id])
        else
          raise "Don't know how to get article for action: #{params[:action]}"
      end
    end

    def setup_categories
      @categories = Category.order('UPPER(name) ASC')
    end

    def setup_resources
      @resources = Resource.order(created_at: :desc)
    end

end
