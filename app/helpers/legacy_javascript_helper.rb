# Copied out of source views in:
#
#   https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/JavaScriptHelper.html
#
module LegacyJavascriptHelper

  JS_ESCAPE_MAP	=	{ '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/JavaScriptHelper.html#M002236
  #
  def options_for_javascript(options)
    if options.empty?
      '{}'
    else
      "{#{options.keys.map { |k| "#{k}:#{options[k]}" }.sort.join(', ')}}"
    end
  end

end
