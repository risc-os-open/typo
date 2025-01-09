module ArticlesHelper
  include SidebarHelper

  def admin_tools_for(model)
    type = model.class.to_s.downcase

    return tag.div(id: "admin_#{type}_#{model.id}", style: 'display: none') do
      link_to_remote(
        'nuke',
        {
          url:      { action: "nuke_#{type}", id: model },
          complete: visual_effect(:puff, "#{type}-#{model.id}", duration: 0.6),
          confirm: "Are you sure you want to delete this #{type}?"
        },
        class: 'admintools'
      )
      .concat link_to(
        'edit',
        {
          controller: "admin/#{type.pluralize}",
          article_id: model.article.id,
          action:     'edit',
          id:         model
        },
        class: 'admintools'
      )
    end
  end

  def onhover_show_admin_tools(type, id = nil)
    tag = ''
    tag << %{ onmouseover="if (getCookie('typoapp_is_admin') == 'yes') { Element.show('admin_#{[type, id].compact.join('_')}'); }" }
    tag << %{ onmouseout="Element.hide('admin_#{[type, id].compact.join('_')}');" }
    tag.html_safe()
  end

  def render_errors(obj)
    return "" unless obj
    tag = String.new

    unless obj.errors.empty?
      tag << %{<ul class="objerrors">}

      obj.errors.each_full do |message|
        tag << "<li>#{message}</li>"
      end

      tag << "</ul>"
    end

    tag
  end

  def page_title
    blog_name = this_blog.blog_name || "Typo"
    if @page_title
      # this is where the page title prefix (string) should go
      (this_blog.title_prefix == 1 ? blog_name + " : " : '') + @page_title + (this_blog.title_prefix == 2 ? " : " + blog_name : '')
    else
      blog_name
    end
  end

  def page_header
    page_header_includes = contents.compact.collect { |c| c.whiteboard }.collect do |w|
      w.select {|k,v| k =~ /^page_header_/}.collect do |(k,v)|
        v = v.chomp
        # trim the same number of spaces from the beginning of each line
        # this way plugins can indent nicely without making ugly source output
        spaces = /\A[ \t]*/.match(v)[0].gsub(/\t/, "  ")
        v.gsub!(/^#{spaces}/, '  ') # add 2 spaces to line up with the assumed position of the surrounding tags
      end
    end.flatten.uniq
    (
      <<~HTML
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        #{ meta_tag 'ICBM', this_blog.geourl_location unless this_blog.geourl_location.empty? }
        <link rel="EditURI" type="application/rsd+xml" title="RSD" href="#{ url_for :controller => '/xml', :action => 'rsd' }" />
        <link rel="alternate" type="application/atom+xml" title="Atom" href="#{ @auto_discovery_url_atom }" />
        <link rel="alternate" type="application/rss+xml" title="RSS" href="#{ @auto_discovery_url_rss }" />
        #{ javascript_include_tag "application" }
        #{ page_header_includes.join("\n") }
        <script type="text/javascript">#{ content_for('script') }</script>
      HTML
    ).chomp.html_safe
  end

  def article_links(article)
    code = []
    code << category_links(article)   unless article.categories.empty?
    code << tag_links(article)        unless article.tags.empty?
    code << comments_link(article)    if article.allow_comments?
    code << trackbacks_link(article)  if article.allow_pings?

    code.join("&nbsp;<strong>|</strong>&nbsp;").html_safe()
  end

  def category_links(article)
    ('Posted in ' + article.categories.map { |c| link_to h(c.name), c.permalink_url, rel: 'tag'}.join(', ')).html_safe()
  end

  def tag_links(article)
    ('Tags ' + article.tags.map { |tag| link_to tag.display_name, tag.permalink_url, rel: 'tag'}.sort.join(', ')).html_safe()
  end

  def author_link(article)
    html = if this_blog.link_to_author && article.user&.email.present?
      mail_to(article.user.email, article.user.name)
    elsif article.user&.name.present?
      article.user.name
    else
      article.author
    end
  end

  def next_link(article)
    n = article.next
    return  n ? n.link_to_permalink("#{h n.title} &raquo;".html_safe()) : ''
  end

  def prev_link(article)
    p = article.previous
    return p ? n.link_to_permalink("&laquo; #{h p.title}".html_safe()) : ''
  end

  def render_to_string(*args, &block)
    controller.send(:render_to_string, *args, &block)
  end

  # Generate the image tag for a commenters gravatar based on their email address
  # Valid options are described at http://www.gravatar.com/implement.php
  def gravatar_tag(email, options={})
    options.update(:gravatar_id => Digest::MD5.hexdigest(email.strip))
    options[:default] = CGI::escape(options[:default]) if options.include?(:default)
    options[:size] ||= 60

    image_tag("http://www.gravatar.com/avatar.php?" <<
      options.map { |key,value| "#{key}=#{value}" }.sort.join("&"), :class => "gravatar")
  end

  def calc_distributed_class(articles, max_articles, grp_class, min_class, max_class)
    (grp_class.to_prefix rescue grp_class.to_s) +
      ((max_articles == 0) ?
           min_class.to_s :
         (min_class + ((max_class-min_class) * articles.to_f / max_articles).to_i).to_s)
  end

  def link_to_grouping(grp)
    link_to( grp.display_name, urlspec_for_grouping(grp),
             :rel => "tag", :title => title_for_grouping(grp) )
  end

  def urlspec_for_grouping(grouping)
    { :controller => "articles", :action => grouping.class.to_prefix, :id => grouping.permalink }
  end

  def title_for_grouping(grouping)
    "#{pluralize(grouping.article_counter, 'post')} with #{grouping.class.to_s.underscore} '#{grouping.display_name}'"
  end

  def ul_tag_for(grouping_class)
    case
    when grouping_class == Tag
      %{<ul id="taglist" class="tags">}
    when grouping_class == Category
      %{<ul class="categorylist">}
    else
      '<ul>'
    end
  end
end
