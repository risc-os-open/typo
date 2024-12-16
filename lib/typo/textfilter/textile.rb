module Typo
  module Textfilter
    class Textile < TextFilterPlugin::Markup
      plugin_display_name "Textile"
      plugin_description 'Textile markup language'

      def self.help_text
        %{
See the [Textile Quick Reference page](http://hobix.com/textile/quick.html).
}
      end

      def self.filtertext(blog, content, text, params)
        RedCloth.new(text).to_html().html_safe()
      end
    end
  end
end
