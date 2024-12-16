# The methods added to this helper will be available to all templates in the application.
require 'digest/sha1'

module ApplicationHelper
  include Pagy::Frontend

  # Turn the Hub and Rails flash data into a simple series of H2 entries,
  # with Hub data first, Rails flash data next. A container DIV will hold
  # zero or more H2 entries:
  #
  #   <div class="flash">
  #     <h2 class="flash foo">Bar</h2>
  #   </div>
  #
  # ...where "foo" is the flash key, e.g. "alert", "notice" and "Bar" is
  # the flash value, made HTML-safe.
  #
  def apphelp_flash
    data = hubssolib_flash_data()
    html = ""

    return tag.div( :class => 'flash' ) do
      data[ 'hub' ].each do | key, value |
        concat( tag.h2( value, class: "flash #{ key }" ) )
      end

      data[ 'standard' ].each do | key, value |
        concat( tag.h2( value, class: "flash #{ key }" ) )
      end
    end
  end

  # Basic english pluralizer.
  # Axe?
  def pluralize(size, word)
    case size
    when 0 then "no #{word.pluralize}"
    when 1 then "1 #{word}"
    else        "#{size} #{word.pluralize}"
    end
  end

  # Produce a link to the permalink_url of 'item'.
  def link_to_permalink(item, title, anchor=nil)
    anchor = "##{anchor}" if anchor
    link_to(title, "#{item.permalink_url}#{anchor}")
  end

  # The '5 comments' link from the bottom of articles
  def comments_link(article)
    link_to_permalink(article,pluralize(article.published_comments.size, 'comment'),'comments')
  end

  def trackbacks_link(article)
    link_to_permalink(article,pluralize(article.published_trackbacks.size, 'trackback'),'trackbacks')
  end

  def check_cache(aggregator, *args)
    hash = "#{aggregator.to_s}_#{args.collect { |arg| Digest::SHA1.hexdigest(arg) }.join('_') }".to_sym
    controller.cache[hash] ||= aggregator.new(*args)
  end

  def js_distance_of_time_in_words_to_now(date)
    if date
      time = date.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")
    else
      time = Time.now
    end

    tag.span(time, title: time, class: 'typo_date')
  end

  def meta_tag(name, value)
    tag.meta(name: name, content: value) unless value.blank?
  end

  def date(date)
    tag.span(date.utc.strftime("%d. %b"), class: 'typo_date')
  end

  def render_theme(options)
    options[:controller]=Themes::ThemeController.active_theme_name
    render_component(options)
  end

  def toggle_effect(domid, true_effect, true_opts, false_effect, false_opts)
    "$('#{domid}').style.display == 'none' ? new #{false_effect}('#{domid}', {#{false_opts}}) : new #{true_effect}('#{domid}', {#{true_opts}}); return false;"
  end

  def markup_help_popup(markup, text)
    if markup and markup.commenthelp.size > 1
      link_to(
        text,
        url_for(
          controller: 'articles',
          action:     'markup_help',
          id:         markup.id,
          onclick:    '"return popup(this, "Typo Markup Help")'
        )
      )
    else
      ''
    end
  end

  # Deprecated helpers
  def server_url_for(options={})
    typo_deprecated "Use url_for instead"
    url_for(options)
  end

  def config_value(name)
    typo_deprecated "Use this_blog.#{name} instead."
    this_blog.send(name)
  end

  def item_link(title, item, anchor=nil)
    typo_deprecated "Use link_to_permalink instead of item_link"
    link_to_permalink(item, title, anchor)
  end

  alias_method :article_link,     :item_link
  alias_method :page_link,        :item_link
  alias_method :comment_url_link, :item_link

  def url_of(item, only_path=true, anchor=nil)
    typo_deprecated "Use item.permalink_url instead"
    item.permalink_url
  end

  alias_method :trackback_url, :url_of
  alias_method :comment_url,   :url_of
  alias_method :article_url,   :url_of
  alias_method :page_url,      :url_of

  def html(content, what = :all, deprecated = false)
    if deprecated
      msg = "use html(#{content.class.to_s.underscore}" + ((what == :all) ? "" : ", #{what.inspect}") + ")"
      typo_deprecated(msg)
    end

    content.html(what)
  end

  def article_html(article, what = :all)
    html(article, what, true)
  end

  def comment_html(comment)
    html(comment, :body, true)
  end

  def page_html(page)
    html(page, :body, true)
  end

  def strip_html(text)
    typo_deprecated "use text.strip_html"
    text.strip_html
  end
end
