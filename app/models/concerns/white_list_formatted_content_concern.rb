require 'html_pipeline'
require 'selma'

module WhiteListFormattedContentConcern
  extend ActiveSupport::Concern

  # Just a namespace for a modification of HTML Pipeline's defaults.
  #
  class CustomHtmlSanitizationOptions
    CONFIG = Selma::Sanitizer::Config.freeze_config({
      elements: [
        "a",
        "abbr",
        "b",
        "blockquote",
        "br",
        "caption",
        "cite",
        "code",
        "dd",
        "del",
        "dfn",
        "div",
        "dl",
        "dt",
        "em",
        "figcaption",
        "figure",
        "font",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "hr",
        "i",
        "img",
        "ins",
        "kbd",
        "li",
        "ol",
        "p",
        "pre",
        "q",
        "s",
        "small",
        "span",
        "strike",
        "strong",
        "sub",
        "summary",
        "sup",
        "table",
        "tbody",
        "td",
        "tfoot",
        "th",
        "thead",
        "tr",
        "tt",
        "ul",
      ],
      attributes: {
        "a"          => ["href"],
        "blockquote" => ["cite"],
        "del"        => ["cite"],
        "div"        => ["itemscope", "itemtype"],
        "img"        => ["src", "longdesc", "loading", "alt"],
        "ins"        => ["cite"],
        "q"          => ["cite"],
        "source"     => ["srcset"],
        "span"       => ["class"],
        "table"      => ["class"],
        all: [
          "abbr",
          "accept-charset",
          "align",
          "alt",
          "aria-describedby",
          "aria-hidden",
          "aria-label",
          "aria-labelledby",
          "background-color",
          "border",
          "charset",
          "clear",
          "color",
          "cols",
          "colspan",
          "compact",
          "dir",
          "disabled",
          "enctype",
          "hspace",
          "id",
          "ismap",
          "itemprop",
          "label",
          "lang",
          "maxlength",
          "media",
          "method",
          "multiple",
          "name",
          "nowrap",
          "open",
          "readonly",
          "rel",
          "rev",
          "role",
          "rows",
          "rowspan",
          "rules",
          "scope",
          "selected",
          "shape",
          "size",
          "span",
          "start",
          "style",
          "summary",
          "tabindex",
          "title",
          "type",
          "usemap",
          "valign",
          "value",
          "width",
        ],
      },
      protocols: {
        "a"          => { "href" => Selma::Sanitizer::Config::VALID_PROTOCOLS }.freeze,
        "blockquote" => { "cite" => ["http", "https", :relative].freeze },
        "del"        => { "cite" => ["http", "https", :relative].freeze },
        "ins"        => { "cite" => ["http", "https", :relative].freeze },
        "q"          => { "cite" => ["http", "https", :relative].freeze },
        "img"        => {
          "src"      => ["http", "https", :relative].freeze,
          "longdesc" => ["http", "https", :relative].freeze,
        },
      },
    })
  end

  # https://github.com/gjtorikian/html-pipeline#convertfilter
  #
  # Runs through RedCloth, then adds a second pass which auto-links anything
  # not already converted to a link through Textile '"foo":link' markup.
  #
  class RedClothAndAutoLinkConvertFilter < HTMLPipeline::ConvertFilter
    include ActionView::Helpers::TextHelper

    def call(text, context: @context)
      html = RedCloth.new(text).to_html()

      # Sanitization is disabled as we use CustomHtmlSanitizationOptions for
      # that via the HTML pipeline; Auto Link's variant is very aggressive..
      #
      html = auto_link(html, sanitize: false) do | link_text |
        truncate(link_text, length: 55, omission: '&hellip;')
      end

      return html
    end
  end

  # https://github.com/gjtorikian/html-pipeline#nodefilters
  #
  class FootnoteNodeFilter < HTMLPipeline::NodeFilter
    attr_accessor :fn_id_sfx

    SELECTOR             = Selma::Selector.new(match_element: "sup.footnote, p.footnote, a")
    FOOTNOTE_NAME_REGEXP = Regexp.new('^fnr?\d+$')  # E.g. "fn30" or "fnr30"
    FOOTNOTE_HREF_REGEXP = Regexp.new('^#fnr?\d+$') # E.g. "#fn30" or "#fnr30"

    def selector
      SELECTOR
    end

    def handle_element(element)
      if element.tag_name == "a"
        match = FOOTNOTE_NAME_REGEXP.match(element['id'] || '')
        element['id'] << fn_id_sfx if (match)
      else
        match = FOOTNOTE_HREF_REGEXP.match(element['href'] || '')
        element['href'] << fn_id_sfx if (match)
      end
    end
  end

  included do
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    def self.format_attribute(attr_name)
      class << self; include ActionView::Helpers::TagHelper, ActionView::Helpers::TextHelper; end

      define_method(:body)       { read_attribute attr_name }
      define_method(:body_html)  { read_attribute "#{attr_name}_html" }
      define_method(:body_html=) { |value| write_attribute "#{attr_name}_html", value }

      before_save :format_content
    end

    def dom_id
      [self.class.name.downcase.pluralize.dasherize, id] * '-'
    end

    protected

      def format_content
        body.strip! if body.respond_to?(:strip!)
        self.body_html = body.blank? ? '' : body_html_with_formatting
      end

      # 2013-09-04 (ADH): See "body_html_with_formatting" for details.
      #
      @@footnote_name_regexp = Regexp.new('^fnr?\d+$')  # E.g. "fn30" or "fnr30"
      @@footnote_href_regexp = Regexp.new('^#fnr?\d+$') # E.g. "#fn30" or "#fnr30"

      def body_html_with_formatting

        # 2013-09-04 (ADH):
        #
        # On the assumption we are called within a new Post or an edited Post,
        # generate a reasonably-likely-to-be-unique ID. We can't use the model
        # ID as in the "new" case it hasn't been saved yet so doesn't have one.
        #
        # We'll use this to patch up Textile footnote references. There's no
        # way to ask Textile to add a suffix to the IDs and names it generates,
        # so instead post-process the output since we're being called for all
        # generated HTML nodes by the white list engine anyway (see
        # WhiteListHelper stuff in "config/environment.rb" for details). If we
        # don't do this, multiple posts on a page can contain the same footnote
        # IDs/names resulting in invalid HTML and useless HTML anchors.
        #
        # Since the ID is only used for that specific case, we're not *too*
        # worried if it turns out to be non-unique, but given it's based on
        # the time of day down to the microsecond and the post's user ID, it
        # is *extremely* unlikely that a real user would be able to generate
        # two posts with the same ID suffix for footnotes!
        #
        now       = Time.now
        magic_id  = self.respond_to?(:user_id) ? (self.user_id || 0) : 0
        fn_id_sfx = "#{now.to_i}#{now.usec}#{magic_id}"

        # This could be switchable to Markdown one day.
        #
        # convert_filter = HTMLPipeline::ConvertFilter::MarkdownFilter.new
        # node_filter    = ...footnote filter for Markdown...
        #
        convert_filter        = RedClothAndAutoLinkConvertFilter.new
        node_filter           = FootnoteNodeFilter.new
        node_filter.fn_id_sfx = fn_id_sfx
        pipeline              = HTMLPipeline.new(
          convert_filter:      convert_filter,
          sanitization_config: CustomHtmlSanitizationOptions::CONFIG,
          node_filters:        [ node_filter ]
        )

        result = pipeline.call(body)

        return result[:output].html_safe()
      end

  end
end
