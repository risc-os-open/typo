module SidebarHelper
  def render_sidebars
    html = ''.html_safe()

    # Ruby-side sort to avoid an extra database query if 'this_blog.sidebars'
    # has already been loaded. Using ".order" would force a new query.
    #
    this_blog.sidebars.sort { |a, b| a.active_position <=> b.active_position }.each do |sidebar|
      @sidebar = sidebar
      sidebar.parse_request(contents, params)
      controller.response.lifetime = sidebar.lifetime if sidebar.lifetime

      html << tag.div(render_sidebar(sidebar), class: 'template_sidebar_node')
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
