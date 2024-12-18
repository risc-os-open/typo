class TextfilterController < ApplicationController
  def public_action
    filter = params[:filter]
    action = params[:public_action]
    plugin = TextFilter.filters_map[filter]

    if(plugin and plugin.plugin_public_actions.include? action.to_sym)
      render_component(:controller => "plugins/textfilters/#{params[:filter]}",
        :action => params[:public_action], :params => params)
    else
      head :not_found
    end
  end

  def test_action
    render plain: ''
  end
end

