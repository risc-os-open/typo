class XmlController < ContentController
  NORMALIZED_FORMAT_FOR = {'atom' => 'atom10', 'rss' => 'rss20',
    'atom10' => 'atom10', 'rss20' => 'rss20',
    'googlesitemap' => 'googlesitemap' }

  CONTENT_TYPE_FOR = { 'rss20' => 'application/xml',
    'atom10' => 'application/atom+xml',
    'googlesitemap' => 'application/xml' }


  def feed
    @items = Array.new
    @blog  = self.this_blog()
    format = NORMALIZED_FORMAT_FOR[params[:format]]
    mime   = XML_LIKE_MAP[format] || 'application/xml'

    if format == 'atom03'
      headers["Status"] = "301 Moved Permanently"
      return redirect_to(:format=>'atom')
    end

    @feed_title  = @blog.blog_name
    @link        = @blog.base_url
    content_type = "#{mime}; charset=utf-8"

    # 'true' => include private & protected methods #respond_to?'s check.
    #
    if self.respond_to?("prep_#{params[:type]}", true)
      self.send("prep_#{params[:type]}")
    else
      render plain: 'Unsupported action', status: 404
      return
    end

    render action: "#{format}_feed", content_type: content_type
  end

  def itunes
    @feed_title = "#{this_blog.blog_name} Podcast"

    @items = Resource
      .where('itunes_metadata = ?', true)
      .limit(this_blog.limit_rss_display)
      .order('created_at DESC'),

    render(action: 'itunes_feed')
  end

  def articlerss
    redirect_to :action => 'feed', :format => 'rss20', :type => 'article', :id => params[:id]
  end

  def commentrss
    redirect_to :action => 'feed', :format => 'rss20', :type => 'comments'
  end
  def trackbackrss
    redirect_to :action => 'feed', :format => 'rss20', :type => 'trackbacks'
  end

  def rsd
  end

  protected

    def fetch_items(association, order='published_at DESC', limit=nil)
      if association.instance_of?(Symbol)
        association = this_blog.send(association)
      end

      limit ||= this_blog.limit_rss_display

      @items += association
        .find_already_published
        .all
        .limit(limit)
        .order(order)
        .to_a
    end

    def prep_feed
      fetch_items(:articles)
    end

    def prep_comments
      fetch_items(:comments)
      @feed_title << " comments"
    end

    def prep_trackbacks
      fetch_items(:trackbacks)
      @feed_title << " trackbacks"
    end

    def prep_article
      article = this_blog.articles.find(params[:id])
      fetch_items(article.comments, 'published_at DESC', 25)
      @items.unshift(article)
      @feed_title << ": #{article.title}"
      @link = article.permalink_url
    end

    def prep_category
      category = Category.find_by_permalink(params[:id])
      fetch_items(category.articles)
      @feed_title << ": Category #{category.name}"
      @link = category.permalink_url
    end

    def prep_tag
      tag = Tag.retrieve_or_instantiate(name: params[:id])
      fetch_items(tag.articles)
      @feed_title << ": Tag #{tag.display_name}"
      @link = tag.permalink_url
    end

    def prep_sitemap
      fetch_items(:articles, 'created_at DESC', 1000)
      fetch_items(:pages, 'created_at DESC', 1000)
      @items += Category.find_all_with_article_counters(1000)
      @items += Tag.find_all_with_article_counters(1000)
    end

end
