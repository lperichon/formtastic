# coding: utf-8

module Formtastic #:nodoc:

  # Wrappers around form_for (etc) with :builder => SemanticFormBuilder.
  #
  # * semantic_form_for(@post)
  # * semantic_fields_for(@post)
  # * semantic_form_remote_for(@post)
  # * semantic_remote_form_for(@post)
  #
  # Each of which are the equivalent of:
  #
  # * form_for(@post, :builder => Formtastic::SemanticFormBuilder))
  # * fields_for(@post, :builder => Formtastic::SemanticFormBuilder))
  # * form_remote_for(@post, :builder => Formtastic::SemanticFormBuilder))
  # * remote_form_for(@post, :builder => Formtastic::SemanticFormBuilder))
  #
  # Example Usage:
  #
  #   <% semantic_form_for @post do |f| %>
  #     <%= f.input :title %>
  #     <%= f.input :body %>
  #   <% end %>
  #
  # The above examples use a resource-oriented style of form_for() helper where only the @post
  # object is given as an argument, but the generic style is also supported, as are forms with 
  # inline objects (Post.new) rather than objects with instance variables (@post):
  #
  #   <% semantic_form_for :post, @post, :url => posts_path do |f| %>
  #     ...
  #   <% end %>
  #
  #   <% semantic_form_for :post, Post.new, :url => posts_path do |f| %>
  #     ...
  #   <% end %>
  module SemanticFormHelper
    @@builder = Formtastic::SemanticFormBuilder
    mattr_accessor :builder
    
    @@default_field_error_proc = nil
    
    # Override the default ActiveRecordHelper behaviour of wrapping the input.
    # This gets taken care of semantically by adding an error class to the LI tag
    # containing the input.
    FIELD_ERROR_PROC = proc do |html_tag, instance_tag|
      html_tag
    end
    
    def use_custom_field_error_proc(&block)
      @@default_field_error_proc = ::ActionView::Base.field_error_proc
      ::ActionView::Base.field_error_proc = FIELD_ERROR_PROC
      result = yield
      ::ActionView::Base.field_error_proc = @@default_field_error_proc
      result
    end
    
    [:form_for, :fields_for, :remote_form_for].each do |meth|
      src = <<-END_SRC
        def semantic_#{meth}(record_or_name_or_array, *args, &proc)
          options = args.extract_options!
          options[:builder] = @@builder
          options[:html] ||= {}
          
          class_names = options[:html][:class] ? options[:html][:class].split(" ") : []
          class_names << "formtastic"
          class_names << case record_or_name_or_array
            when String, Symbol then record_or_name_or_array.to_s               # :post => "post"
            when Array then record_or_name_or_array.last.class.to_s.underscore  # [@post, @comment] # => "comment"
            else record_or_name_or_array.class.to_s.underscore                  # @post => "post"
          end
          options[:html][:class] = class_names.join(" ")
          
          use_custom_field_error_proc do
            #{meth}(record_or_name_or_array, *(args << options), &proc)
          end
        end
      END_SRC
      module_eval src, __FILE__, __LINE__
    end
    alias :semantic_form_remote_for :semantic_remote_form_for
    
  end
end
