# The Blog class represents one blog.  It stores most configuration settings
# and is linked to most of the assorted content classes via has_many.
#
# Typo decides which Blog object to use by searching for a Blog base_url that
# matches the base_url computed for each request.
class Blog < ApplicationRecord
  include ConfigManager
  include Rails.application.routes.url_helpers # To access #url_for

  def default_url_options # Lets #url_for work properly and provide full URLs
    this_blog_base_url = URI.parse(Current.request&.original_url || self.base_url() || 'http://localhost:3000')

    options            = Rails.application.routes.default_url_options
    options[:host    ] = this_blog_base_url.host
    options[:port    ] = this_blog_base_url.port
    options[:protocol] = this_blog_base_url.scheme

    return options
  end

  has_many :contents
  has_many :trackbacks
  has_many :articles
  has_many :comments
  has_many :pages, -> { order(id: :desc) }
  has_many(
    :published_articles,
    -> { where(published: true).includes(:categories, :tags).order('contents.published_at DESC') },
    class_name: 'Article'
  ) do
    def before(date = Time.now)
      self.all.where('contents.created_at < ?', date)
    end
  end

  has_many :pages
  has_many :comments
  has_many :sidebars, -> { order(active_position: :asc) }

  serialize :settings, coder: YAML, type: Hash

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
  setting :theme,                      :string, 'risc_os_open'
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
    (Blog.find_by(base_url: base_url) rescue nil)|| Blog.default || Blog.new
  end

  # The default Blog.  This is the lowest-numbered blog, almost always id==1.
  def self.default
    self.order('id ASC').first
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
    @cached_theme ||= Theme.retrieve(theme)
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

