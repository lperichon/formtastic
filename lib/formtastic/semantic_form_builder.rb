# coding: utf-8
module Formtastic
  class SemanticFormBuilder < ActionView::Helpers::FormBuilder
  
    @@default_text_field_size = 50
    @@all_fields_required_by_default = true
    @@include_blank_for_select_by_default = true
    @@required_string = proc { %{<abbr title="#{I18n.t 'formtastic.required', :default => 'required'}">*</abbr>} }
    @@optional_string = ''
    @@inline_errors = :sentence
    @@label_str_method = :humanize
    @@collection_label_methods = %w[to_label display_name full_name name title username login value to_s]
    @@inline_order = [ :input, :hints, :errors ]
    @@file_methods = [ :file?, :public_filename ]
    @@priority_countries = ["Australia", "Canada", "United Kingdom", "United States"]
    @@i18n_lookups_by_default = false
    @@default_commit_button_accesskey = nil 
  
    cattr_accessor :default_text_field_size, :all_fields_required_by_default, :include_blank_for_select_by_default,
                   :required_string, :optional_string, :inline_errors, :label_str_method, :collection_label_methods,
                   :inline_order, :file_methods, :priority_countries, :i18n_lookups_by_default, :default_commit_button_accesskey 
  
    I18N_SCOPES = [ '{{model}}.{{action}}.{{attribute}}',
                    '{{model}}.{{attribute}}',
                    '{{attribute}}']
        
    attr_accessor :template
    
    
    protected
    
    include Formtastic::Label
    include Formtastic::Inputs
    include Formtastic::Input
    include Formtastic::Buttons
    
    # Internal generic method for looking up localized values within Formtastic
    # using I18n, if no explicit value is set and I18n-lookups are enabled.
    # 
    # Enabled/Disable this by setting:
    #
    #   Formtastic::SemanticFormBuilder.i18n_lookups_by_default = true/false
    #
    # Lookup priority:
    #
    #   'formtastic.{{type}}.{{model}}.{{action}}.{{attribute}}'
    #   'formtastic.{{type}}.{{model}}.{{attribute}}'
    #   'formtastic.{{type}}.{{attribute}}'
    # 
    # Example:
    #   
    #   'formtastic.labels.post.edit.title'
    #   'formtastic.labels.post.title'
    #   'formtastic.labels.title'
    # 
    # NOTE: Generic, but only used for form input labels/hints.
    #
    def localized_string(key, value, type, options = {})
      key = value if value.is_a?(::Symbol)
  
      if value.is_a?(::String)
        value
      else
        use_i18n = value.nil? ? @@i18n_lookups_by_default : (value != false)
  
        if use_i18n
          model_name  = (@object ? @object.class.name : @object_name.to_s.send(@@label_str_method)).underscore
          action_name = template.params[:action].to_s rescue ''
          attribute_name = key.to_s
  
          defaults = I18N_SCOPES.collect do |i18n_scope|
            i18n_path = i18n_scope.dup
            i18n_path.gsub!('{{action}}', action_name)
            i18n_path.gsub!('{{model}}', model_name)
            i18n_path.gsub!('{{attribute}}', attribute_name)
            i18n_path.gsub!('..', '.')
            i18n_path.to_sym
          end
          defaults << ''
  
          i18n_value = ::I18n.t(defaults.shift, options.merge(:default => defaults,
                                :scope => :"formtastic.#{type.to_s.pluralize}"))
          i18n_value.blank? ? nil : i18n_value
        end
      end
    end
    
    
    private
    
    def send_or_call(duck, object)
      if duck.is_a?(Proc)
        duck.call(object)
      else
        object.send(duck)
      end
    end
    
    def set_include_blank(options)
      unless options.key?(:include_blank) || options.key?(:prompt)
        options[:include_blank] = @@include_blank_for_select_by_default
      end
      options
    end
  
  end
  
end 