# coding: utf-8

module Formtastic # :nodoc:
  module Inputs
  
    # Creates an input fieldset and ol tag wrapping for use around a set of inputs.  It can be
    # called either with a block (in which you can do the usual Rails form stuff, HTML, ERB, etc),
    # or with a list of fields.  These two examples are functionally equivalent:
    #
    #   # With a block:
    #   <% semantic_form_for @post do |form| %>
    #     <% form.inputs do %>
    #       <%= form.input :title %>
    #       <%= form.input :body %>
    #     <% end %>
    #   <% end %>
    #
    #   # With a list of fields:
    #   <% semantic_form_for @post do |form| %>
    #     <%= form.inputs :title, :body %>
    #   <% end %>
    #
    #   # Output:
    #   <form ...>
    #     <fieldset class="inputs">
    #       <ol>
    #         <li class="string">...</li>
    #         <li class="text">...</li>
    #       </ol>
    #     </fieldset>
    #   </form>
    #
    # === Quick Forms
    #
    # When called without a block or a field list, an input is rendered for each column in the
    # model's database table, just like Rails' scaffolding.  You'll obviously want more control
    # than this in a production application, but it's a great way to get started, then come back
    # later to customise the form with a field list or a block of inputs.  Example:
    #
    #   <% semantic_form_for @post do |form| %>
    #     <%= form.inputs %>
    #   <% end %>
    #
    # === Options
    #
    # All options (with the exception of :name) are passed down to the fieldset as HTML
    # attributes (id, class, style, etc).  If provided, the :name option is passed into a
    # legend tag inside the fieldset (otherwise a legend is not generated).
    #
    #   # With a block:
    #   <% semantic_form_for @post do |form| %>
    #     <% form.inputs :name => "Create a new post", :style => "border:1px;" do %>
    #       ...
    #     <% end %>
    #   <% end %>
    #
    #   # With a list (the options must come after the field list):
    #   <% semantic_form_for @post do |form| %>
    #     <%= form.inputs :title, :body, :name => "Create a new post", :style => "border:1px;" %>
    #   <% end %>
    #
    # === It's basically a fieldset!
    #
    # Instead of hard-coding fieldsets & legends into your form to logically group related fields,
    # use inputs:
    #
    #   <% semantic_form_for @post do |f| %>
    #     <% f.inputs do %>
    #       <%= f.input :title %>
    #       <%= f.input :body %>
    #     <% end %>
    #     <% f.inputs :name => "Advanced", :id => "advanced" do %>
    #       <%= f.input :created_at %>
    #       <%= f.input :user_id, :label => "Author" %>
    #     <% end %>
    #   <% end %>
    #
    #   # Output:
    #   <form ...>
    #     <fieldset class="inputs">
    #       <ol>
    #         <li class="string">...</li>
    #         <li class="text">...</li>
    #       </ol>
    #     </fieldset>
    #     <fieldset class="inputs" id="advanced">
    #       <legend><span>Advanced</span></legend>
    #       <ol>
    #         <li class="datetime">...</li>
    #         <li class="select">...</li>
    #       </ol>
    #     </fieldset>
    #   </form>
    #
    # === Nested attributes
    #
    # As in Rails, you can use semantic_fields_for to nest attributes:
    #
    #   <% semantic_form_for @post do |form| %>
    #     <%= form.inputs :title, :body %>
    #
    #     <% form.semantic_fields_for :author, @bob do |author_form| %>
    #       <% author_form.inputs do %>
    #         <%= author_form.input :first_name, :required => false %>
    #         <%= author_form.input :last_name %>
    #       <% end %>
    #     <% end %>
    #   <% end %>
    #
    # But this does not look formtastic! This is equivalent:
    #
    #   <% semantic_form_for @post do |form| %>
    #     <%= form.inputs :title, :body %>
    #     <% form.inputs :for => [ :author, @bob ] do |author_form| %>
    #       <%= author_form.input :first_name, :required => false %>
    #       <%= author_form.input :last_name %>
    #     <% end %>
    #   <% end %>
    #
    # And if you don't need to give options to your input call, you could do it
    # in just one line:
    #
    #   <% semantic_form_for @post do |form| %>
    #     <%= form.inputs :title, :body %>
    #     <%= form.inputs :first_name, :last_name, :for => @bob %>
    #   <% end %>
    #
    # Just remember that calling inputs generates a new fieldset to wrap your
    # inputs. If you have two separate models, but, semantically, on the page
    # they are part of the same fieldset, you should use semantic_fields_for
    # instead (just as you would do with Rails' form builder).
    #
    def inputs(*args, &block)
      html_options = args.extract_options!
      html_options[:class] ||= "inputs"
    
      if html_options[:for]
        inputs_for_nested_attributes(args, html_options, &block)
      elsif block_given?
        field_set_and_list_wrapping(html_options, &block)
      else
        if @object && args.empty?
          args  = @object.class.reflections.map { |n,_| n if _.macro == :belongs_to }
          args += @object.class.content_columns.map(&:name)
          args -= %w[created_at updated_at created_on updated_on lock_version version]
          args.compact!
        end
        contents = args.map { |method| input(method.to_sym) }
    
        field_set_and_list_wrapping(html_options, contents)
      end
    end
    alias :input_field_set :inputs
    
    # A thin wrapper around #fields_for to set :builder => Formtastic::SemanticFormBuilder
    # for nesting forms:
    #
    #   # Example:
    #   <% semantic_form_for @post do |post| %>
    #     <% post.semantic_fields_for :author do |author| %>
    #       <% author.inputs :name %>
    #     <% end %>
    #   <% end %>
    #
    #   # Output:
    #   <form ...>
    #     <fieldset class="inputs">
    #       <ol>
    #         <li class="string"><input type='text' name='post[author][name]' id='post_author_name' /></li>
    #       </ol>
    #     </fieldset>
    #   </form>
    #
    def semantic_fields_for(record_or_name_or_array, *args, &block)
      opts = args.extract_options!
      opts.merge!(:builder => Formtastic::SemanticFormHelper.builder)
      args.push(opts)
      fields_for(record_or_name_or_array, *args, &block)
    end
    
    # Generates a fieldset and wraps the content in an ordered list. When working
    # with nested attributes (in Rails 2.3), it allows %i as interpolation option
    # in :name. So you can do:
    #
    #   f.inputs :name => 'Task #%i', :for => :tasks
    #
    # And it will generate a fieldset for each task with legend 'Task #1', 'Task #2',
    # 'Task #3' and so on.
    #
    def field_set_and_list_wrapping(html_options, contents='', &block) #:nodoc:
      html_options[:name] ||= html_options.delete(:title)
      html_options[:name] = localized_string(html_options[:name], html_options[:name], :title) if html_options[:name].is_a?(Symbol)
    
      legend  = html_options.delete(:name).to_s
      legend %= parent_child_index(html_options[:parent]) if html_options[:parent]
      legend  = template.content_tag(:legend, template.content_tag(:span, legend)) unless legend.blank?
    
      if block_given?
        contents = if template.respond_to?(:is_haml?) && template.is_haml?
          template.capture_haml(&block)
        else
          template.capture(&block)
        end
      end
    
      # Ruby 1.9: String#to_s behavior changed, need to make an explicit join.
      contents = contents.join if contents.respond_to?(:join)
      fieldset = template.content_tag(:fieldset,
        legend + template.content_tag(:ol, contents),
        html_options.except(:builder, :parent)
      )
    
      template.concat(fieldset) if block_given?
      fieldset
    end
    
    # Generates error messages for the given method. Errors can be shown as list
    # or as sentence. If :none is set, no error is shown.
    #
    # This method is also aliased as errors_on, so you can call on your custom
    # inputs as well:
    #
    #   semantic_form_for :post do |f|
    #     f.text_field(:body)
    #     f.errors_on(:body)
    #   end
    def inline_errors_for(method, options=nil) #:nodoc:
      return nil unless @object && @object.respond_to?(:errors) && [:sentence, :list].include?(inline_errors)
  
      errors = @object.errors[method.to_sym]
      send("error_#{inline_errors}", Array(errors)) unless errors.blank?
    end
    alias :errors_on :inline_errors_for
    
    # Generates hints for the given method using the text supplied in :hint.
    def inline_hints_for(method, options) #:nodoc:
      options[:hint] = localized_string(method, options[:hint], :hint)
      return if options[:hint].blank?
      template.content_tag(:p, options[:hint], :class => 'inline-hints')
    end
    
    protected
    
    # Deals with :for option when it's supplied to inputs methods. Additional
    # options to be passed down to :for should be supplied using :for_options
    # key.
    #
    # It should raise an error if a block with arity zero is given.
    #
    def inputs_for_nested_attributes(args, options, &block)
      args << options.merge!(:parent => { :builder => self, :for => options[:for] })
    
      fields_for_block = if block_given?
        raise ArgumentError, 'You gave :for option with a block to inputs method, ' <<
                             'but the block does not accept any argument.' if block.arity <= 0
    
        proc { |f| f.inputs(*args){ block.call(f) } }
      else
        proc { |f| f.inputs(*args) }
      end
    
      fields_for_args = [options.delete(:for), options.delete(:for_options) || {}].flatten
      semantic_fields_for(*fields_for_args, &fields_for_block)
    end
    
    # Generates an input for the given method using the type supplied with :as.
    def inline_input_for(method, options)
      send("#{options.delete(:as)}_input", method, options)
    end
  
    # Creates an error sentence by calling to_sentence on the errors array.
    def error_sentence(errors) #:nodoc:
      template.content_tag(:p, errors.to_sentence.untaint, :class => 'inline-errors')
    end
  
    # Creates an error ul list.
    def error_list(errors) #:nodoc:
      list_elements = []
      errors.each do |error|
        list_elements <<  template.content_tag(:li, error.untaint)
      end
      template.content_tag(:ul, list_elements.join("\n"), :class => 'errors')
    end
    
  end
end