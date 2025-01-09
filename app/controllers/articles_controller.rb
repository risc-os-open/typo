class ArticlesController < ContentController
  before_action :verify_config

  layout :theme_layout, :except => [:comment_preview, :trackback]

  before_action only: [:nuke_comment, :nuke_trackback] do
    unless request.post? && hubssolib_current_user().present?
      render plain: 'Forbidden', status: 403
    end
  end

  HUBSSOLIB_PERMISSIONS = HubSsoLib::Permissions.new(
    {
      read_and_comment: [ :admin, :webmaster, :privileged, :normal ]
    }
  )

  def self.hubssolib_permissions
    HUBSSOLIB_PERMISSIONS
  end

  def index
    scope = this_blog
      .published_articles
      .where('contents.published_at < ?', Time.now)

    @articles_pages, @articles = pagy_with_params(scope: scope, default_limit: 5)
  end

  def search
    @articles = this_blog.published_articles.search(params[:q])
    render_paginated_index("No articles found...")
  end

  def comment_preview
    if params[:comment].blank? or params[:comment][:body].blank?
      head :ok
      return
    end

    safe_params = Comment.params_for_new(params, :comment, required: true)
    @comment = this_blog.comments.build(safe_params)
    @comment.author = hubssolib_unique_name() unless hubssolib_privileged?
  end

  def archives
    @articles = this_blog.published_articles
  end

  def read
    display_article { this_blog.published_articles.find(params[:id]) }
  end

  def read_and_comment
    display_article(nil, 'read_and_comment') {
      this_blog.published_articles.find(params[:id])
    }
  end

  def permalink
    display_article(this_blog.published_articles.find_by_permalink(*params.values_at(:year, :month, :day, :title)))
  end

  def find_by_date
    @articles = this_blog.published_articles.find_all_by_date(params[:year], params[:month], params[:day])
    render_paginated_index
  end

  def error(message = "Record not found...")
    @message = message.to_s
    render :action => 'error'
  end

  def author
    render_grouping(User)
  end

  def category
    render_grouping(Category)
  end

  def tag
    render_grouping(Tag)
  end

  # Receive comments to articles
  def comment
    unless request.xhr? || this_blog.sp_allow_non_ajax_comments
      render_error("non-ajax commenting is disabled")
      return
    end

    unless hubssolib_logged_in?
      render_error("You are not logged in; you cannot comment on articles")
      return
    end

    if request.post?
      begin
        @article = this_blog.published_articles.find(params[:id])

        safe_params = Comment.params_for_new(params, :comment, required: true)
        safe_params.merge!({
          ip:         request.remote_ip,
          published:  true,
          user_id:    session.dig('user', 'id'),
          user_agent: request.env['HTTP_USER_AGENT'],
          referrer:   request.env['HTTP_REFERER'],
          permalink:  @article.permalink_url
        })

        @comment = @article.comments.build(safe_params)

        @comment.author   = hubssolib_unique_name() unless hubssolib_privileged?
        @comment.author ||= 'Anonymous'
        @comment.save!

        add_to_cookies(:typoapp_author, @comment.author)
        add_to_cookies(:typoapp_url,    @comment.url)

        render partial: 'comment', object: @comment
      rescue ActiveRecord::RecordInvalid
        Rails.logger.error @comment.errors.inspect
        render_error(@comment)
      end
    end
  end

  # Receive trackbacks linked to articles
  def trackback
    @error_message = catch(:error) do
      if params[:__mode] == "rss"
        # Part of the trackback spec... will implement later
        # XXX. Should this throw an error?
      elsif !(params.has_key?(:url) && params.has_key?(:id))
        throw :error, "A URL is required"
      else
        begin
          settings = { :id => params[:id],
                       :url => params[:url],      :blog_name => params[:blog_name],
                       :title => params[:title],  :excerpt => params[:excerpt],
                       :ip  => request.remote_ip, :published => true }
          this_blog.ping_article!(settings)
        rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid
          throw :error, "Article id #{params[:id]} not found."
        rescue ActiveRecord::RecordInvalid
          throw :error, "Trackback not saved"
        end
      end
      nil
    end

    render formats: :xml
  end

  def nuke_comment
    Comment.find(params[:id]).destroy
    render :nothing => true
  end

  def nuke_trackback
    Trackback.find(params[:id]).destroy
    render :nothing => true
  end

  def view_page
    if(@page = Page.find_by(name: params[:name].to_a.join('/')))
      @page_title = @page.title
    else
      render :nothing => true, :status => 404
    end
  end

  def markup_help
    render layout: 'minimal', html: TextFilter.find(params[:id]).commenthelp
  end

  private

    def add_to_cookies(name, value)
      cookies[name] = { :value => value, :path => url_for(:controller => :articles, :action => :index, :only_path => true),
                        :expires => 6.weeks.from_now }
    end

    def verify_config
      if User.count == 0
        redirect_to :controller => "accounts", :action => "signup"
      elsif ! this_blog.is_ok?
        redirect_to :controller => "admin/general", :action => "redirect"
      else
        return true
      end
    end

    def display_article(article = nil, action = 'read')
      begin
        @article      = block_given? ? yield : article
        @comment      = Comment.new
        @page_title   = @article.title
        auto_discovery_feed :type => 'article', :id => @article.id
        render :action => action
      rescue ActiveRecord::RecordNotFound
        error("Post not found...")
      end
    end

    alias_method :rescue_action_in_public, :error

    def render_error(object = '', status = 500)
      render(:text => (object.errors.full_messages.join(", ") rescue object.to_s), :status => status)
    end

    def list_groupings(klass)
      @grouping_class = klass
      @groupings = klass.find_all_with_article_counters(1000)
      render :action => 'groupings'
    end

    def render_grouping(klass)
      return list_groupings(klass) unless params[:id]

      @page_title = "#{klass.to_s.underscore} #{params[:id]}"
      @articles = klass.find_by_permalink(params[:id]).articles.find_already_published rescue []
      auto_discovery_feed :type => klass.to_s.underscore, :id => params[:id]
      render_paginated_index("Can't find posts with #{klass.to_prefix} '#{h(params[:id])}'")
    end

    def render_paginated_index(on_empty = "No posts found...")
      return error(on_empty) if @articles.empty?

      scope = @articles # (sic.)
      @articles_pages, @articles = pagy_with_params(scope: scope)

      render :action => 'index'
    end

end
