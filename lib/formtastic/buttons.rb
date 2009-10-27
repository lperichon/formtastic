# coding: utf-8

module Formtastic # :nodoc:
  module Buttons
  
    # Creates a fieldset and ol tag wrapping for form buttons / actions as list items.
    # See inputs documentation for a full example.  The fieldset's default class attriute
    # is set to "buttons".
    #
    # See inputs for html attributes and special options.
    def buttons(*args, &block)
      html_options = args.extract_options!
      html_options[:class] ||= "buttons"
    
      if block_given?
        field_set_and_list_wrapping(html_options, &block)
      else
        args = [:commit] if args.empty?
        contents = args.map { |button_name| send(:"#{button_name}_button") }
        field_set_and_list_wrapping(html_options, contents)
      end
    end
    alias :button_field_set :buttons
    
    
    # Creates a submit input tag with the value "Save [model name]" (for existing records) or
    # "Create [model name]" (for new records) by default:
    #
    #   <%= form.commit_button %> => <input name="commit" type="submit" value="Save Post" />
    #
    # The value of the button text can be overridden:
    #
    #  <%= form.commit_button "Go" %> => <input name="commit" type="submit" value="Go" class="{create|update|submit}" />
    #  <%= form.commit_button :label => "Go" %> => <input name="commit" type="submit" value="Go" class="{create|update|submit}" />
    #
    # And you can pass html atributes down to the input, with or without the button text:
    #
    #  <%= form.commit_button "Go" %> => <input name="commit" type="submit" value="Go" class="{create|update|submit}" />
    #  <%= form.commit_button :class => "pretty" %> => <input name="commit" type="submit" value="Save Post" class="pretty {create|update|submit}" />
    #
    def commit_button(*args)
      options = args.extract_options!
      text = options.delete(:label) || args.shift
  
      if @object
        key = @object.new_record? ? :create : :update
        object_name = @object.class.human_name
  
        if key == :update
          # Note: Fallback on :save-key (deprecated), :update makes more sense in the REST-world.
          fallback_text = ::I18n.t(:save, :model => object_name, :default => "Save {{model}}", :scope => [:formtastic])
          ::ActiveSupport::Deprecation.warn "Formtastic I18n: Key 'formtastic.save' is now deprecated in favor 'formtastic.update'."
        end
      else
        key = :submit
        object_name = @object_name.to_s.send(label_str_method)
      end
      fallback_text ||= "#{key.to_s.humanize} {{model}}"
  
      text = (self.localized_string(key, text, :action, :model => object_name) ||
              ::I18n.t(key, :model => object_name, :default => fallback_text, :scope => [:formtastic])) unless text.is_a?(::String)
  
      button_html = options.delete(:button_html) || {}
      button_html.merge!(:class => [button_html[:class], key].compact.join(' '))
      element_class = ['commit', options.delete(:class)].compact.join(' ') # TODO: Add class reflecting on form action.
      accesskey = (options.delete(:accesskey) || default_commit_button_accesskey) unless button_html.has_key?(:accesskey)
      button_html = button_html.merge(:accesskey => accesskey) if accesskey  
      template.content_tag(:li, self.submit(text, button_html), :class => element_class)
    end
  
  end
end