# Copied out of source views in:
#
#   https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html
#
module LegacyPrototypeHelper

  CALLBACKS = Set.new(
    %i(
      create
      uninitialized
      loading
      loaded
      interactive
      complete
      failure
      success
    ) + (100..599).to_a
  )

  AJAX_OPTIONS = Set.new(
    %i(
      before
      after
      condition
      url
      asynchronous
      method
      insertion
      position
      form
      with
      update
      script
      type
    )
  ).merge(CALLBACKS)

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002169
  #
  def form_remote_tag(options = {}, &block)
    options[:form] = true

    options[:html] ||= {}
    options[:html][:onsubmit] =
      (options[:html][:onsubmit] ? options[:html][:onsubmit] + "; " : "") +
      "#{remote_function(options)}; return false;"

    form_tag(options[:html].delete(:action) || url_for(options[:url]), options[:html], &block)
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002166
  #
  def link_to_remote(name, options = {}, html_options = nil)
    link_to_function(name, remote_function(options), html_options || options.delete(:html))
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002175
  #
  def observe_field(field_id, options = {})
    if options[:frequency] && options[:frequency] > 0
      build_observer('Form.Element.Observer', field_id, options)
    else
      build_observer('Form.Element.EventObserver', field_id, options)
    end
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002176
  #
  def observe_form(form_id, options = {})
    if options[:frequency]
      build_observer('Form.Observer', form_id, options)
    else
      build_observer('Form.EventObserver', form_id, options)
    end
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002174
  #
  def remote_function(options)
    javascript_options = options_for_ajax(options)

    update = ''
    if options[:update] && options[:update].is_a?(Hash)
      update  = []
      update << "success:'#{options[:update][:success]}'" if options[:update][:success]
      update << "failure:'#{options[:update][:failure]}'" if options[:update][:failure]
      update  = '{' + update.join(',') + '}'
    elsif options[:update]
      update << "'#{options[:update]}'"
    end

    function = update.empty? ?
      "new Ajax.Request(" :
      "new Ajax.Updater(#{update}, "

    url_options = options[:url]
    url_options = url_options.merge(:escape => false) if url_options.is_a?(Hash)
    function << "'#{escape_javascript(url_for(url_options))}'"
    function << ", #{javascript_options})"

    function = "#{options[:before]}; #{function}" if options[:before]
    function = "#{function}; #{options[:after]}"  if options[:after]
    function = "if (#{options[:condition]}) { #{function}; }" if options[:condition]
    function = "if (confirm('#{escape_javascript(options[:confirm])}')) { #{function}; }" if options[:confirm]

    return function.html_safe()
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002177
  #
  def update_page(&block)
    raise 'Unexpected render context' unless self.is_a?(ActionView::Base)
    JavaScriptGenerator.new(self, &block).to_s.html_safe
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002182
  #
  def build_callbacks(options)
    callbacks = {}
    options.each do |callback, code|
      if CALLBACKS.include?(callback)
        name = 'on' + callback.to_s.capitalize
        callbacks[name] = "function(request){#{code}}"
      end
    end
    callbacks
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002181
  #
  def build_observer(klass, name, options = {})
    if options[:with] && (options[:with] !~ /[\{=(.]/)
      options[:with] = "'#{options[:with]}=' + encodeURIComponent(value)"
    else
      options[:with] ||= 'value' unless options[:function]
    end

    callback = options[:function] || remote_function(options)
    javascript  = "new #{klass}('#{name}', "
    javascript << "#{options[:frequency]}, " if options[:frequency]
    javascript << "function(element, value) {"
    javascript << "#{callback}}"
    javascript << ")"

    javascript_tag(javascript)
  end

  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper.html#M002179
  #
  def options_for_ajax(options)
    js_options = build_callbacks(options)

    js_options['asynchronous'] = options[:type] != :synchronous
    js_options['method']       = method_option_to_s(options[:method]) if options[:method]
    js_options['insertion']    = "'#{options[:position].to_s.downcase}'" if options[:position]
    js_options['evalScripts']  = options[:script].nil? || options[:script]

    if options[:form]
      js_options['parameters'] = 'Form.serialize(this)'
    elsif options[:submit]
      js_options['parameters'] = "Form.serialize('#{options[:submit]}')"
    elsif options[:with]
      js_options['parameters'] = options[:with]
    end

    if protect_against_forgery? && !options[:form]
      if js_options['parameters']
        js_options['parameters'] << " + '&"
      else
        js_options['parameters'] = "'"
      end
      js_options['parameters'] << "#{request_forgery_protection_token}=' + encodeURIComponent('#{escape_javascript form_authenticity_token}')"
    end

    options_for_javascript(js_options)
  end

  # ============================================================================
  # Embedded class taken directly from the RubyGems v2.3.18 download at
  # https://rubygems.org/gems/actionpack/versions/2.3.18.
  #
  # https://api.rubyonrails.org/v2.3.8/classes/ActionView/Helpers/PrototypeHelper/JavaScriptGenerator/GeneratorMethods.html
  # ============================================================================

      # All the methods were moved to GeneratorMethods so that
      # #include_helpers_from_context has nothing to overwrite.
      class JavaScriptGenerator #:nodoc:
        def initialize(context, &block) #:nodoc:
          @context, @lines = context, []
          include_helpers_from_context
          @context.with_output_buffer(@lines) do
            @context.instance_exec(self, &block)
          end
        end

        private
          def include_helpers_from_context
            extend @context.helpers if @context.respond_to?(:helpers)
            extend GeneratorMethods
          end

        # JavaScriptGenerator generates blocks of JavaScript code that allow you
        # to change the content and presentation of multiple DOM elements.  Use
        # this in your Ajax response bodies, either in a <script> tag or as plain
        # JavaScript sent with a Content-type of "text/javascript".
        #
        # Create new instances with PrototypeHelper#update_page or with
        # ActionController::Base#render, then call +insert_html+, +replace_html+,
        # +remove+, +show+, +hide+, +visual_effect+, or any other of the built-in
        # methods on the yielded generator in any order you like to modify the
        # content and appearance of the current page.
        #
        # Example:
        #
        #   # Generates:
        #   #     new Element.insert("list", { bottom: "<li>Some item</li>" });
        #   #     new Effect.Highlight("list");
        #   #     ["status-indicator", "cancel-link"].each(Element.hide);
        #   update_page do |page|
        #     page.insert_html :bottom, 'list', "<li>#{@item.name}</li>"
        #     page.visual_effect :highlight, 'list'
        #     page.hide 'status-indicator', 'cancel-link'
        #   end
        #
        #
        # Helper methods can be used in conjunction with JavaScriptGenerator.
        # When a helper method is called inside an update block on the +page+
        # object, that method will also have access to a +page+ object.
        #
        # Example:
        #
        #   module ApplicationHelper
        #     def update_time
        #       page.replace_html 'time', Time.now.to_s(:db)
        #       page.visual_effect :highlight, 'time'
        #     end
        #   end
        #
        #   # Controller action
        #   def poll
        #     render(:update) { |page| page.update_time }
        #   end
        #
        # Calls to JavaScriptGenerator not matching a helper method below
        # generate a proxy to the JavaScript Class named by the method called.
        #
        # Examples:
        #
        #   # Generates:
        #   #     Foo.init();
        #   update_page do |page|
        #     page.foo.init
        #   end
        #
        #   # Generates:
        #   #     Event.observe('one', 'click', function () {
        #   #       $('two').show();
        #   #     });
        #   update_page do |page|
        #     page.event.observe('one', 'click') do |p|
        #      p[:two].show
        #     end
        #   end
        #
        # You can also use PrototypeHelper#update_page_tag instead of
        # PrototypeHelper#update_page to wrap the generated JavaScript in a
        # <script> tag.
        module GeneratorMethods
          def to_s #:nodoc:
            (@lines * $/).tap do |javascript|
              source = javascript.dup
              javascript.replace "try {\n#{source}\n} catch (e) "
              javascript << "{ alert('RJS error:\\n\\n' + e.toString()); alert('#{source.gsub('\\','\0\0').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }}'); throw e }"
            end
          end

          # Returns a element reference by finding it through +id+ in the DOM. This element can then be
          # used for further method calls. Examples:
          #
          #   page['blank_slate']                  # => $('blank_slate');
          #   page['blank_slate'].show             # => $('blank_slate').show();
          #   page['blank_slate'].show('first').up # => $('blank_slate').show('first').up();
          #
          # You can also pass in a record, which will use ActionController::RecordIdentifier.dom_id to lookup
          # the correct id:
          #
          #   page[@post]     # => $('post_45')
          #   page[Post.new]  # => $('new_post')
          def [](id)
            case id
              when String, Symbol, NilClass
                JavaScriptElementProxy.new(self, id)
              else
                JavaScriptElementProxy.new(self, ActionController::RecordIdentifier.dom_id(id))
            end
          end

          # Returns an object whose <tt>to_json</tt> evaluates to +code+. Use this to pass a literal JavaScript
          # expression as an argument to another JavaScriptGenerator method.
          def literal(code)
            ::ActiveSupport::JSON::Variable.new(code.to_s)
          end

          # Returns a collection reference by finding it through a CSS +pattern+ in the DOM. This collection can then be
          # used for further method calls. Examples:
          #
          #   page.select('p')                      # => $$('p');
          #   page.select('p.welcome b').first      # => $$('p.welcome b').first();
          #   page.select('p.welcome b').first.hide # => $$('p.welcome b').first().hide();
          #
          # You can also use prototype enumerations with the collection.  Observe:
          #
          #   # Generates: $$('#items li').each(function(value) { value.hide(); });
          #   page.select('#items li').each do |value|
          #     value.hide
          #   end
          #
          # Though you can call the block param anything you want, they are always rendered in the
          # javascript as 'value, index.'  Other enumerations, like collect() return the last statement:
          #
          #   # Generates: var hidden = $$('#items li').collect(function(value, index) { return value.hide(); });
          #   page.select('#items li').collect('hidden') do |item|
          #     item.hide
          #   end
          #
          def select(pattern)
            JavaScriptElementCollectionProxy.new(self, pattern)
          end

          # Inserts HTML at the specified +position+ relative to the DOM element
          # identified by the given +id+.
          #
          # +position+ may be one of:
          #
          # <tt>:top</tt>::    HTML is inserted inside the element, before the
          #                    element's existing content.
          # <tt>:bottom</tt>:: HTML is inserted inside the element, after the
          #                    element's existing content.
          # <tt>:before</tt>:: HTML is inserted immediately preceding the element.
          # <tt>:after</tt>::  HTML is inserted immediately following the element.
          #
          # +options_for_render+ may be either a string of HTML to insert, or a hash
          # of options to be passed to ActionView::Base#render.  For example:
          #
          #   # Insert the rendered 'navigation' partial just before the DOM
          #   # element with ID 'content'.
          #   # Generates: Element.insert("content", { before: "-- Contents of 'navigation' partial --" });
          #   page.insert_html :before, 'content', :partial => 'navigation'
          #
          #   # Add a list item to the bottom of the <ul> with ID 'list'.
          #   # Generates: Element.insert("list", { bottom: "<li>Last item</li>" });
          #   page.insert_html :bottom, 'list', '<li>Last item</li>'
          #
          def insert_html(position, id, *options_for_render)
            content = javascript_object_for(render(*options_for_render))
            record "Element.insert(\"#{id}\", { #{position.to_s.downcase}: #{content} });"
          end

          # Replaces the inner HTML of the DOM element with the given +id+.
          #
          # +options_for_render+ may be either a string of HTML to insert, or a hash
          # of options to be passed to ActionView::Base#render.  For example:
          #
          #   # Replace the HTML of the DOM element having ID 'person-45' with the
          #   # 'person' partial for the appropriate object.
          #   # Generates:  Element.update("person-45", "-- Contents of 'person' partial --");
          #   page.replace_html 'person-45', :partial => 'person', :object => @person
          #
          def replace_html(id, *options_for_render)
            call 'Element.update', id, render(*options_for_render)
          end

          # Replaces the "outer HTML" (i.e., the entire element, not just its
          # contents) of the DOM element with the given +id+.
          #
          # +options_for_render+ may be either a string of HTML to insert, or a hash
          # of options to be passed to ActionView::Base#render.  For example:
          #
          #   # Replace the DOM element having ID 'person-45' with the
          #   # 'person' partial for the appropriate object.
          #   page.replace 'person-45', :partial => 'person', :object => @person
          #
          # This allows the same partial that is used for the +insert_html+ to
          # be also used for the input to +replace+ without resorting to
          # the use of wrapper elements.
          #
          # Examples:
          #
          #   <div id="people">
          #     <%= render :partial => 'person', :collection => @people %>
          #   </div>
          #
          #   # Insert a new person
          #   #
          #   # Generates: new Insertion.Bottom({object: "Matz", partial: "person"}, "");
          #   page.insert_html :bottom, :partial => 'person', :object => @person
          #
          #   # Replace an existing person
          #
          #   # Generates: Element.replace("person_45", "-- Contents of partial --");
          #   page.replace 'person_45', :partial => 'person', :object => @person
          #
          def replace(id, *options_for_render)
            call 'Element.replace', id, render(*options_for_render)
          end

          # Removes the DOM elements with the given +ids+ from the page.
          #
          # Example:
          #
          #  # Remove a few people
          #  # Generates: ["person_23", "person_9", "person_2"].each(Element.remove);
          #  page.remove 'person_23', 'person_9', 'person_2'
          #
          def remove(*ids)
            loop_on_multiple_args 'Element.remove', ids
          end

          # Shows hidden DOM elements with the given +ids+.
          #
          # Example:
          #
          #  # Show a few people
          #  # Generates: ["person_6", "person_13", "person_223"].each(Element.show);
          #  page.show 'person_6', 'person_13', 'person_223'
          #
          def show(*ids)
            loop_on_multiple_args 'Element.show', ids
          end

          # Hides the visible DOM elements with the given +ids+.
          #
          # Example:
          #
          #  # Hide a few people
          #  # Generates: ["person_29", "person_9", "person_0"].each(Element.hide);
          #  page.hide 'person_29', 'person_9', 'person_0'
          #
          def hide(*ids)
            loop_on_multiple_args 'Element.hide', ids
          end

          # Toggles the visibility of the DOM elements with the given +ids+.
          # Example:
          #
          #  # Show a few people
          #  # Generates: ["person_14", "person_12", "person_23"].each(Element.toggle);
          #  page.toggle 'person_14', 'person_12', 'person_23'      # Hides the elements
          #  page.toggle 'person_14', 'person_12', 'person_23'      # Shows the previously hidden elements
          #
          def toggle(*ids)
            loop_on_multiple_args 'Element.toggle', ids
          end

          # Displays an alert dialog with the given +message+.
          #
          # Example:
          #
          #   # Generates: alert('This message is from Rails!')
          #   page.alert('This message is from Rails!')
          def alert(message)
            call 'alert', message
          end

          # Redirects the browser to the given +location+ using JavaScript, in the same form as +url_for+.
          #
          # Examples:
          #
          #  # Generates: window.location.href = "/mycontroller";
          #  page.redirect_to(:action => 'index')
          #
          #  # Generates: window.location.href = "/account/signup";
          #  page.redirect_to(:controller => 'account', :action => 'signup')
          def redirect_to(location)
            url = location.is_a?(String) ? location : @context.url_for(location)
            record "window.location.href = #{url.inspect}"
          end

          # Reloads the browser's current +location+ using JavaScript
          #
          # Examples:
          #
          #  # Generates: window.location.reload();
          #  page.reload
          def reload
            record 'window.location.reload()'
          end

          # Calls the JavaScript +function+, optionally with the given +arguments+.
          #
          # If a block is given, the block will be passed to a new JavaScriptGenerator;
          # the resulting JavaScript code will then be wrapped inside <tt>function() { ... }</tt>
          # and passed as the called function's final argument.
          #
          # Examples:
          #
          #   # Generates: Element.replace(my_element, "My content to replace with.")
          #   page.call 'Element.replace', 'my_element', "My content to replace with."
          #
          #   # Generates: alert('My message!')
          #   page.call 'alert', 'My message!'
          #
          #   # Generates:
          #   #     my_method(function() {
          #   #       $("one").show();
          #   #       $("two").hide();
          #   #    });
          #   page.call(:my_method) do |p|
          #      p[:one].show
          #      p[:two].hide
          #   end
          def call(function, *arguments, &block)
            record "#{function}(#{arguments_for_call(arguments, block)})"
          end

          # Assigns the JavaScript +variable+ the given +value+.
          #
          # Examples:
          #
          #  # Generates: my_string = "This is mine!";
          #  page.assign 'my_string', 'This is mine!'
          #
          #  # Generates: record_count = 33;
          #  page.assign 'record_count', 33
          #
          #  # Generates: tabulated_total = 47
          #  page.assign 'tabulated_total', @total_from_cart
          #
          def assign(variable, value)
            record "#{variable} = #{javascript_object_for(value)}"
          end

          # Writes raw JavaScript to the page.
          #
          # Example:
          #
          #  page << "alert('JavaScript with Prototype.');"
          def <<(javascript)
            @lines << javascript
          end

          # Executes the content of the block after a delay of +seconds+. Example:
          #
          #   # Generates:
          #   #     setTimeout(function() {
          #   #     ;
          #   #     new Effect.Fade("notice",{});
          #   #     }, 20000);
          #   page.delay(20) do
          #     page.visual_effect :fade, 'notice'
          #   end
          def delay(seconds = 1)
            record "setTimeout(function() {\n\n"
            yield
            record "}, #{(seconds * 1000).to_i})"
          end

          # Starts a script.aculo.us visual effect. See
          # ActionView::Helpers::ScriptaculousHelper for more information.
          def visual_effect(name, id = nil, options = {})
            record @context.send(:visual_effect, name, id, options)
          end

          # Creates a script.aculo.us sortable element. Useful
          # to recreate sortable elements after items get added
          # or deleted.
          # See ActionView::Helpers::ScriptaculousHelper for more information.
          def sortable(id, options = {})
            record @context.send(:sortable_element_js, id, options)
          end

          # Creates a script.aculo.us draggable element.
          # See ActionView::Helpers::ScriptaculousHelper for more information.
          def draggable(id, options = {})
            record @context.send(:draggable_element_js, id, options)
          end

          # Creates a script.aculo.us drop receiving element.
          # See ActionView::Helpers::ScriptaculousHelper for more information.
          def drop_receiving(id, options = {})
            record @context.send(:drop_receiving_element_js, id, options)
          end

          private
            def loop_on_multiple_args(method, ids)
              record(ids.size>1 ?
                "#{javascript_object_for(ids)}.each(#{method})" :
                "#{method}(#{::ActiveSupport::JSON.encode(ids.first)})")
            end

            def page
              self
            end

            def record(line)
              "#{line.to_s.chomp.gsub(/\;\z/, '')};".tap do |_line|
                self << _line
              end
            end

            def render(*options_for_render)
              old_format = @context && @context.template_format
              @context.template_format = :html if @context
              Hash === options_for_render.first ?
                @context.render(*options_for_render) :
                  options_for_render.first.to_s
            ensure
              @context.template_format = old_format if @context
            end

            def javascript_object_for(object)
              ::ActiveSupport::JSON.encode(object)
            end

            def arguments_for_call(arguments, block = nil)
              arguments << block_to_function(block) if block
              arguments.map { |argument| javascript_object_for(argument) }.join ', '
            end

            def block_to_function(block)
              generator = self.class.new(@context, &block)
              literal("function() { #{generator.to_s} }")
            end

            def method_missing(method, *arguments)
              JavaScriptProxy.new(self, method.to_s.camelize)
            end
        end
      end

end
