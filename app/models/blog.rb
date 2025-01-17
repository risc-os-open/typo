# BlogRequest is a fake Request object, created so blog.url_for will work.
class BlogRequest

  attr_accessor :protocol, :host_with_port, :path, :symbolized_path_parameters, :relative_url_root

  def initialize(root)
    @protocol = @host_with_port = @path = ''
    @symbolized_path_parameters = {}
    @relative_url_root = root.gsub(%r{/^},'')
  end
end

# The Blog class represents one blog.  It stores most configuration settings
# and is linked to most of the assorted content classes via has_many.
#
# Typo decides which Blog object to use by searching for a Blog base_url that
# matches the base_url computed for each request.
class Blog < CachedModel
  include ConfigManager

  has_many :contents
  has_many :trackbacks
  has_many :articles
  has_many :comments
  has_many :pages, :order => "id DESC"
  has_many(:published_articles, :class_name => "Article",
           :conditions => {:published => true},
           :include => [:categories, :tags],
           :order => "contents.published_at DESC") do
    def before(date = Time.now)
      find(:all, :conditions => ["contents.created_at < ?", date])
    end
  end

  has_many :pages
  has_many :comments
  has_many :sidebars, :order => 'active_position ASC'

  serialize :settings, Hash

  # Description
  setting :blog_name,                  :string, 'My Shiny Weblog!'
  setting :blog_subtitle,              :string, ''
  setting :title_prefix,               :integer, 0
  setting :geourl_location,            :string, ''
  setting :canonical_server_url,       :string, ''  # Deprecated

  # Spam
  setting :sp_global,                  :boolean, false
  setting :sp_article_auto_close,      :integer, 0
  setting :sp_allow_non_ajax_comments, :boolean, true
  setting :sp_url_limit,               :integer, 0
  setting :sp_akismet_key,             :string, ''

  # Podcasting
  setting :itunes_explicit,            :boolean, false
  setting :itunes_author,              :string, ''
  setting :itunes_subtitle,            :string, ''
  setting :itunes_summary,             :string, ''
  setting :itunes_owner,               :string, ''
  setting :itunes_email,               :string, ''
  setting :itunes_name,                :string, ''
  setting :itunes_copyright,           :string, ''

  # Mostly Behaviour
  setting :text_filter,                :string, ''
  setting :comment_text_filter,        :string, ''
  setting :limit_article_display,      :integer, 10
  setting :limit_rss_display,          :integer, 10
  setting :default_allow_pings,        :boolean, false
  setting :default_allow_comments,     :boolean, true
  setting :default_moderate_comments,  :boolean, false
  setting :link_to_author,             :boolean, false
  setting :show_extended_on_rss,       :boolean, true
  setting :theme,                      :string, 'azure'
  setting :use_gravatar,               :boolean, false
  setting :global_pings_disable,       :boolean, false
  setting :ping_urls,                  :string, "http://rpc.technorati.com/rpc/ping\nhttp://ping.blo.gs/\nhttp://rpc.weblogs.com/RPC2"
  setting :send_outbound_pings,        :boolean, true
  setting :email_from,                 :string, 'typo@example.com'

  # Jabber config
  setting :jabber_address,             :string, ''
  setting :jabber_password,            :string, ''

  def initialize(*args)
    super
    # Yes, this is weird - PDC
    begin
      self.settings ||= {}
    rescue Exception => e
      self.settings = {}
    end
  end

  # Find the Blog that matches a specific base URL.  If no Blog object is found
  # that matches, then grab the default blog.  If *that* fails, then create a new
  # Blog.  The last case should only be used when Typo is first installed.
  def self.find_blog(base_url)
    (Blog.find_by_base_url(base_url) rescue nil)|| Blog.default || Blog.new
  end

  # The default Blog.  This is the lowest-numbered blog, almost always id==1.
  def self.default
    find(:first, :order => 'id')
  end

  def ping_article!(settings)
    settings[:blog_id] = self.id
    article_id = settings[:id]
    settings.delete(:id)
    trackback = published_articles.find(article_id).trackbacks.create!(settings)
  end

  # Check that all required blog settings have a value.
  def is_ok?
    settings.has_key?('blog_name')
  end

  # The +Theme+ object for the current theme.
  def current_theme
    @cached_theme ||= Theme.find(theme)
  end

  # Generate a URL based on the +base_url+.  This allows us to generate URLs
  # without needing a controller handy, so we can produce URLs from within models
  # where appropriate.
  #
  # It also uses our new RouteCache, so repeated URL generation requests should be
  # fast, as they bypass all of Rails' route logic.
  def url_for(options = {}, *extra_params)
    case options
    when String then options # They asked for 'url_for "/some/path"', so return it unedited.
    when Hash
      unless RouteCache[options]
        options.reverse_merge!(:only_path => true, :controller => '/articles',
                               :action => 'permalink')
        # Remove internal semi-hack that valiantly attempts to isolate
        # code from needing a Controller but does so at the expense of
        # assuming protocol and port, based on the admin-set blog base
        # URL. Replace it with global (ugh) set in prime_url_writer,
        # a before_filter in application.rb.
        #
        # @url ||= ActionController::UrlRewriter.new(BlogRequest.new(self.base_url), {})
        @url ||= ActionController::UrlRewriter.new($url_writer_request_information, {})
        RouteCache[options] = @url.rewrite(options)
      end

      return RouteCache[options]
    else
      raise "Invalid URL in url_for: #{options.inspect}"
    end
  end

  # The URL for a static file.
  def file_url(filename)
    "#{base_url}/files/#{filename}"
  end

  # The base server URL.
  def server_url
    base_url
  end

  # Deprecated
  def canonical_server_url
    typo_deprecated "Use base_url instead"
    base_url
  end

  def [](key)  # :nodoc:
    typo_deprecated "Use blog.#{key}"
    self.send(key)
  end

  def []=(key, value)  # :nodoc:
    typo_deprecated "Use blog.#{key}="
    self.send("#{key}=", value)
  end

  def has_key?(key)  # :nodoc:
    typo_deprecated "Why?"
    self.class.fields.has_key?(key.to_s)
  end

  def find_already_published(content_type)  # :nodoc:
    typo_deprecated "Use #{content_type}.find_already_published"
    self.send(content_type).find_already_published
  end

  def current_theme_path  # :nodoc:
    typo_deprecated "use current_theme.path"
    Theme.themes_root + "/" + theme
  end
end

