require 'uri'
require 'net/http'

class Article < Content
  include TypoGuid

  content_fields :body, :extended

  self.permitted_params_for_new = [
    :title,
    :body,
    :extended,
    :keywords,
    :permalink,
    :allow_comments,
    :allow_pings,
    :published,
    :published_at,
    :text_filter,
    { categories: [] }, # This is a HABTM association
  ]

  self.permitted_params_for_edit = self.permitted_params_for_new

  has_many :pings,      -> { order(created_at: :asc) }, dependent: :destroy
  has_many :comments,   -> { order(created_at: :asc) }, dependent: :destroy, class_name: 'Comment'
  has_many :trackbacks, -> { order(created_at: :asc) }, dependent: :destroy, class_name: 'Trackback'
  has_many :resources,
           -> { order(created_at: :desc) },
           class_name:  'Resource',
           foreign_key: 'article_id'

  has_many :categorizations
  has_many :categories, through: :categorizations do
    def push_with_attributes(cat, join_attrs = { :is_primary => false })
      Categorization.with_scope(:create => join_attrs) { self << cat }
    end
  end

  has_and_belongs_to_many :tags, foreign_key: 'article_id', join_table: 'articles_tags'
  belongs_to :user
  has_many :triggers, as: :pending_item

  after_save :send_pings
  after_save :send_notifications
  after_destroy :fix_resources

  def stripped_title
    self.title.gsub(/<[^>]*>/,'').to_url
  end

  def permalink_url(anchor = nil, only_path = true)
    blog.article_permalink_url(
      year:       published_at.year,
      month:      sprintf("%.2d", published_at.month),
      day:        sprintf("%.2d", published_at.day),
      title:      permalink,
      anchor:     anchor,
      only_path:  only_path,
      controller: '/articles'
    )
  end

  def trackback_url
    blog.url_for(:controller => "articles", :action =>"trackback", :id => id)
  end

  def feed_url(format = :rss20)
    blog.url_for(:controller => 'xml', :action => 'feed', :type => 'article', :format => format, :id => id)
  end

  def edit_url
    blog.url_for(:controller => "admin/content", :action =>"edit", :id => id)
  end

  def delete_url
    blog.url_for(:controller => "admin/content", :action =>"destroy", :id => id)
  end

  def html_urls
    urls = Array.new
    html.gsub(/<a [^>]*>/) do |tag|
      if(tag =~ /href="([^"]+)"/)
        urls.push($1)
      end
    end

    urls.uniq
  end

  def really_send_pings(serverurl = blog.base_url, articleurl = nil)
    return unless blog.send_outbound_pings

    articleurl ||= permalink_url(nil, false)

    weblogupdatesping_urls = blog.ping_urls.gsub(/ +/,'').split(/[\n\r]+/)
    pingback_or_trackback_urls = self.html_urls

    ping_urls = weblogupdatesping_urls + pingback_or_trackback_urls

    ping_urls.uniq.each do |url|
      begin
        unless pings.collect { |p| p.url }.include?(url.strip)
          ping = pings.build("url" => url)

          if weblogupdatesping_urls.include?(url)
            ping.send_weblogupdatesping(serverurl, articleurl)
          elsif pingback_or_trackback_urls.include?(url)
            ping.send_pingback_or_trackback(articleurl)
          end
        end
      rescue Exception => e
        Rails.logger.error(e)
        # in case the remote server doesn't respond or gives an error,
        # we should throw an xmlrpc error here.
      end
    end
  end

  def send_pings
    state.send_pings(self)
  end

  def next
    blog
      .articles
      .where('published_at > ?', published_at)
      .order(published_at: :asc)
      .first
  end

  def previous
    blog
      .articles
      .where('published_at < ?', published_at)
      .order(published_at: :desc)
      .first
  end

  # Count articles on a certain date
  def self.count_by_date(year, month = nil, day = nil, limit = nil)
    from, to = self.time_delta(year, month, day)

    Article
      .where(published: true, published_at: from...to)
      .count
  end

  # Find all articles on a certain date
  def self.find_all_by_date(year, month = nil, day = nil)
    from, to = self.time_delta(year, month, day)

    Article
      .order(default_order)
      .where(published: true, published_at: from...to)
  end

  # Find one article on a certain date

  def self.find_by_date(year, month, day)
    find_all_by_date(year, month, day).first
  end

  # Finds one article which was posted on a certain date and matches the supplied dashed-title
  def self.find_by_permalink(year, month, day, title)
    from, to = self.time_delta(year, month, day)

    Article
      .order(default_order)
      .where(published: true, published_at: from...to, permalink: title)
      .first!
  end

  # Fulltext searches the body of published articles
  def self.search(query)
    if !query.to_s.strip.empty?
      tokens = query.split.collect {|c| "%#{c.downcase}%"}

      Article
        .order(default_order)
        .where(published: true)
        .where(
          (["(LOWER(body) LIKE ? OR LOWER(extended) LIKE ? OR LOWER(title) LIKE ?)"] * tokens.size).join(" AND "),
          *tokens.collect { |token| [token] * 3 }.flatten
        )
    else
      Article.none
    end
  end

  def keywords_to_tags
    Article.transaction do
      tags.clear
      keywords.to_s.scan(/((['"]).*?\2|[\.\w]+)/).collect do |x|
        x.first.tr("\"'", '')
      end.uniq.each do |tagword|
        tags << Tag.get(tagword)
      end
    end
  end

  def interested_users
    User.where(notify_on_new_articles: true)
  end

  def notify_user_via_email(user)
    if user.notify_via_email?
      EmailNotify.send_article(self, user)
    end
  end

  def notify_user_via_jabber(user)
    if user.notify_via_jabber?
      JabberNotify.send_message(user, "New post",
                                "A new message was posted to #{blog.blog_name}",
                                html(:body))
    end
  end

  def comments_closed?
    if self.allow_comments?
      if !self.blog.sp_article_auto_close.zero? and self.created_at.to_i < self.blog.sp_article_auto_close.days.ago.to_i
        return true
      else
        return false
      end
    else
      return true
    end
  end

  def published_comments
    comments.select {|c| c.published?}
  end

  def published_trackbacks
    trackbacks.select {|c| c.published?}
  end

  # Bloody rails reloading. Nasty workaround.
  def body=(newval)
    if self[:body] != newval
      changed
      self[:body] = newval
    end
    self[:body]
  end

  def body_html
    typo_deprecated "Use html(:body)"
    html(:body)
  end

  def extended=(newval)
    if self[:extended] != newval
      changed
      self[:extended] = newval
    end
    self[:extended]
  end

  def extended_html
    typo_deprecated "Use html(:extended)"
    html(:extended)
  end

  def self.html_map(field=nil)
    html_map = { :body => true, :extended => true }
    if field
      html_map[field.to_sym]
    else
      html_map
    end
  end

  def content_fields
    [:body, :extended]
  end

  protected

  before_create :set_defaults, :create_guid
  after_validation :set_published_at_if_unset
  after_save :keywords_to_tags
  after_create :add_notifications

  def set_published_at_if_unset
    self.published_at ||= Time.now if self.published
  end

  def set_defaults
    if self.attributes.include?("permalink") and self.permalink.blank?
      self.permalink = self.stripped_title
    end
    if blog && self.allow_comments.nil?
      self.allow_comments = blog.default_allow_comments
    end

    if blog && self.allow_pings.nil?
      self.allow_pings = blog.default_allow_pings
    end

    true
  end

  def add_notifications
    self.notify_users = User.where(notify_on_new_articles: true)

    if self.user.present? && self.user.notify_watch_my_articles == true && self.user.notify_on_new_articles == false
      self.notify_users = self.notify_users.or(User.where(id: self.user.id))
    end

    return self.notify_users
  end

  # This returns a start-inclusive, end-exclusive from-to tuple in UTC. If
  # putting into an ActiveRecord query using a range, be sure to use "..." to
  # get the correct ">= from, < to" semantics in the query.
  #
  def self.time_delta(year, month = nil, day = nil)
    from = Time.utc(year, month || 1, day || 1)

    to = from + 1.day
    to = from.next_month unless month.blank?
    to = from + 1.day unless day.blank?

    return [from, to]
  end

  validates_uniqueness_of :guid
  validates_presence_of :title

  private

    def fix_resources
      Resource.where(article_id: self.id).find_each do |fu|
        fu.article_id = nil
        fu.save
      end
    end

end
