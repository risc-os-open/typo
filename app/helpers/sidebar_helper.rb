module SidebarHelper
  def render_sidebars
    this_blog.sidebars.inject('') do |acc, sb|
      @sidebar = sb
      sb.parse_request(contents, params)
      controller.response.lifetime = sb.lifetime if sb.lifetime
      acc + render_sidebar(sb)
    end.html_safe()
  end

  def render_sidebar(sidebar)
    partial_name = sidebar.class.name.demodulize.underscore

    render_to_string(
      partial: "sidebar/sidebars/#{partial_name}",
      locals:   sidebar.to_locals_hash
    )
  end
end
