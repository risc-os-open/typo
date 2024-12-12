class Sidebars::Field
  attr_accessor :key
  attr_accessor :options
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper

  def initialize(key = nil, options = { })
    @key, @options = key.to_s, options
  end

  def label_html(sidebar)
    content_tag('label', options[:label] || key.humanize.gsub(/url/i, 'URL'))
  end

  def input_html(sidebar)
    text_field_tag(input_name(sidebar), sidebar.config[key], options)
  end

  def line_html(sidebar)
    label_html(sidebar) +  "<br />" + input_html(sidebar) + "<br />"
  end

  def input_name(sidebar)
    "configure[#{sidebar.id}][#{key}]"
  end

  class SelectField < self
    def input_html(sidebar)
      select_tag(input_name(sidebar),
                 options_for_select(options[:choices], sidebar.config[key]),
                 options)
    end
  end

  class TextAreaField < self
    def input_html(sidebar)
      html_options = { "rows" => "10", "cols" => "30", "style" => "width:255px"}.update(options.stringify_keys)
      text_area_tag(input_name(sidebar), h(sidebar.config[key]), html_options)
    end
  end

  class RadioField < self
    def input_html(sidebar)
      options[:choices].collect do |choice|
        value = value_for(choice)
        radio_button_tag(input_name(sidebar), value,
                         value == sidebar.config[key], options) +
          content_tag('label', label_for(choice))
      end.join("<br />")
    end

    def label_for(choice)
      choice.is_a?(Array) ? choice.last : choice.to_s.humanize
    end

    def value_for(choice)
      choice.is_a?(Array) ? choice.first : choice
    end
  end

  class CheckBoxField < self
    def input_html(sidebar)
      check_box_tag(input_name(sidebar), 1, sidebar.config[key], options)+
      hidden_field_tag(input_name(sidebar),0)
    end

    def line_html(sidebar)
      input_html(sidebar) + ' ' + label_html(sidebar) + '<br >'
    end
  end

  def self.build(key, options)
    field = class_for(options).new(key, options)
  end

  def self.class_for(options)
    case options[:input_type]
    when :text_area
      TextAreaField
    when :textarea
      TextAreaField
    when :radio
      RadioField
    when :checkbox
      CheckBoxField
    when :select
      SelectField
    else
      if options[:choices]
        SelectField
      else
        self
      end
    end
  end
end
