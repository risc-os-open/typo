# Copied out of source views in:
#
#   https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/ScriptaculousHelper.html
#
# ...with very minor modernisation here and there.
#
module LegacyScriptaculousHelper

  TOGGLE_EFFECTS = [:toggle_appear, :toggle_slide, :toggle_blind]

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/ScriptaculousHelper.html#M002158
  #
  def visual_effect(name, element_id = false, js_options = {})
     element = element_id ? ActiveSupport::JSON.encode(element_id) : "element"

    js_options[:queue] = if js_options[:queue].is_a?(Hash)
      '{' + js_options[:queue].map {|k, v| k == :limit ? "#{k}:#{v}" : "#{k}:'#{v}'" }.join(',') + '}'
    elsif js_options[:queue]
      "'#{js_options[:queue]}'"
    end if js_options[:queue]

    [:endcolor, :direction, :startcolor, :scaleMode, :restorecolor].each do |option|
      js_options[option] = "'#{js_options[option]}'" if js_options[option]
    end

    if TOGGLE_EFFECTS.include? name.to_sym
      "Effect.toggle(#{element},'#{name.to_s.gsub(/^toggle_/,'')}',#{options_for_javascript(js_options)});".html_safe()
    else
      "new Effect.#{name.to_s.camelize}(#{element},#{options_for_javascript(js_options)});".html_safe()
    end
  end

end
