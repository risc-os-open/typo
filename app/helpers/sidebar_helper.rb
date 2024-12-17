module SidebarHelper
  def render_sidebars
    html = ''.html_safe()

    # Ruby-side sort to avoid an extra database query if 'this_blog.sidebars'
    # has already been loaded. Using ".order" would force a new query.
    #
    this_blog.sidebars.sort { |a, b| a.id <=> b.id }.each do |sidebar|
      @sidebar = sidebar
      sidebar.parse_request(contents, params)
      controller.response.lifetime = sidebar.lifetime if sidebar.lifetime

      html << render_sidebar(sidebar)
    end

    return html
  end

  def render_sidebar(sidebar)
    partial_name = sidebar.class.name.demodulize.underscore

    render_to_string(
      partial: "sidebar/sidebars/#{partial_name}",
      locals:   sidebar.to_locals_hash
    )
  end
end
