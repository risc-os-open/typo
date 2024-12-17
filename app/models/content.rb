require 'observer'
require 'set'

class Content < ApplicationRecord
  include Observable

  belongs_to :text_filter
  belongs_to :blog
  validates_presence_of :blog_id

  composed_of :state, :class_name => 'ContentState::Factory',
    :mapping => %w{ state memento }

  has_many :notifications, foreign_key: 'content_id'
  has_many :notify_users, through: :notifications, source: 'notify_user'

  def notify_users=(collection)
    return notify_users.clear if collection.empty?
    self.class.transaction do
      self.notifications.clear
      collection.uniq.each do |u|
        self.notifications.build(:notify_user => u)
      end
      notify_users.target = collection
    end
  end

  has_many :triggers, :as => :pending_item, :dependent => :delete_all

  before_save :state_before_save
  after_save :post_trigger, :state_after_save

  serialize :whiteboard, coder: YAML, type: Hash

  @@content_fields = Hash.new
  @@html_map       = Hash.new

  def initialize(*args, &block)
    super(*args, &block)
    set_default_blog
  end

  def invalidates_cache?(on_destruction = false)
    if on_destruction
      just_changed_published_status? || published?
    else
      changed? && published? || just_changed_published_status?
    end
  end

  def set_default_blog
    if self.blog_id == nil or self.blog_id == 0
      self.blog = Blog.default
    end
  end

  class << self
    # Quite a bit of this isn't needed anymore.
    def content_fields(*attribs)
      @@content_fields[self] = ((@@content_fields[self]||[]) + attribs).uniq
      @@html_map[self] = nil
      attribs.each do | field |
        define_method("#{field}=") do | newval |
          if self.read_attribute(field) != newval
            changed
            self.write_attribute(field, newval)
          end

          # Always return the cast value by re-reading, since this may differ
          # from the type of 'newval' - e.g. string "21" in 'id' -> integer 21.
          #
          self.read_attribute(field)
        end

        unless self.method_defined?("#{field}_html")
          define_method("#{field}_html") do
            typo_deprecated "Use html(:#{field})"
            html(field.to_sym)
          end
        end
      end
    end

    def html_map(field=nil)
      unless @@html_map[self]
        @@html_map[self] = Hash.new
        instance = self.new
        @@content_fields[self].each do |attrib|
          @@html_map[self][attrib] = true
        end
      end
      if field
        @@html_map[self][field]
      else
        @@html_map[self]
      end
    end

    def default_order
      'published_at DESC'
    end

    def find_already_published
      self
        .order(default_order)
        .where(published: true)
        .where('published_at < ?', Time.now)
    end
  end

  def content_fields
    @@content_fields[self.class]
  end

  def state_before_save
    state.before_save(self)
  end

  def state_after_save
    state.after_save(self)
  end

  def html_map(field=nil)
    self.class.html_map(field)
  end

  def cache_key(field)
    id ? "contents_html/#{id}/#{field}" : nil
  end

  # Return HTML for some part of this object.  It will be fetched from the
  # cache if possible, or regenerated if needed.
  def html(field = :all)
    if field == :all
      generate_html(:all, content_fields.map{|f| self.read_attribute(f).to_s}.join("\n\n"))
    elsif self.class.html_map(field)
      generate_html(field)
    else
      raise "Unknown field: #{field.inspect} in article.html"
    end
  end

  # Generate HTML for a specific field using the text_filter in use for this
  # object.  The HTML is cached in the fragment cache, using the +ContentCache+
  # object in @@cache.
  def generate_html(field, text = nil)
    text ||= self.read_attribute(field).to_s
    html = text_filter.filter_text_for_content(blog, text, self)
    html ||= text # just in case the filter puked
    html_postprocess(field,html).to_s
  end

  # Post-process the HTML.  This is a noop by default, but Comment overrides it
  # to enforce HTML sanity.
  def html_postprocess(field,html)
    html
  end

  def whiteboard
    attr_value = self.read_attribute(:whiteboard)

    if attr_value.nil?
      new_hash = Hash.new
      self.write_attribute(:whiteboard, new_hash)
      return new_hash
    else
      return attr_value
    end
  end

  # The default text filter.  Generally, this is the filter specified by blog.text_filter,
  # but comments may use a different default.
  def default_text_filter
    blog.text_filter.to_text_filter
  end

  # Grab the text filter for this object.  It's either the filter specified by
  # self.text_filter_id, or the default specified in the blog object.
  def text_filter
    filter_id = self.read_attribute(:text_filter_id)
    filter    = TextFilter.find_by_id(filter_id) if filter_id.present? && ! filter_id.zero?

    return filter || default_text_filter
  end

  # Set the text filter for this object.
  def text_filter=(filter)
    returning(filter.to_text_filter) { |tf| self.text_filter_id = tf.id }
  end

  # Changing the title flags the object as changed
  def title=(new_title)
    old_title = self.get_attribute(:title)
    if new_title == old_title
      old_title
    else
      self.changed()
      self.write_attribute(:title, new_title)
    end
  end

  # Overrides the association accessor behind the 'blog_id' column, to allow
  # fallback to a default blog.
  #
  def blog

    # Try to avoid an ActiveRecord query, cached or otherwise
    #
    if self[:blog_id] == Current.blog.id
      Current.blog
    else
      super || Blog.default
    end
  end

  def state=(newstate)
    if state
      state.exit_hook(self, newstate)
    end
    @state = newstate
    self.write_attribute(:state, newstate.memento)
    newstate.enter_hook(self)
    @state
  end

  def publish!
    self.published = true
    self.save!
  end

  def withdraw
    state.withdraw(self)
  end

  def withdraw!
    self.withdraw
    self.save!
  end

  def published=(a_boolean)
    self.write_attribute(:published, a_boolean)
    state.change_published_state(self, a_boolean)
  end

  def published_at=(a_time)
    state.set_published_at(self, (a_time.to_time rescue nil))
  end

  def published_at
    self.read_attribute(:published_at) || self.read_attribute(:created_at)
  end

  def published?
    state.published?(self)
  end

  def just_published?
    state.just_published?
  end

  def just_changed_published_status?
    state.just_changed_published_status?
  end

  def withdrawn?
    state.withdrawn?
  end

  def publication_pending?
    state.publication_pending?
  end

  def post_trigger
    state.post_trigger(self)
  end

  def after_save
    state.after_save(self)
  end

  def send_notification_to_user(user)
    notify_user_via_email(user)
    notify_user_via_jabber(user)
  end

  def send_notifications()
    state.send_notifications(self)
  end

  # deprecated
  def full_html
    typo_deprecated "use .html instead"
    html
  end

end
