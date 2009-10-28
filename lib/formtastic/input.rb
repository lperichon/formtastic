module Formtastic
  module Input
    # Returns a suitable form input for the given +method+, using the database column information
    # and other factors (like the method name) to figure out what you probably want.
    #
    # Options:
    #
    # * :as - override the input type (eg force a :string to render as a :password field)
    # * :label - use something other than the method name as the label text, when false no label is printed
    # * :required - specify if the column is required (true) or not (false)
    # * :hint - provide some text to hint or help the user provide the correct information for a field
    # * :input_html - provide options that will be passed down to the generated input
    # * :wrapper_html - provide options that will be passed down to the li wrapper
    #
    # Input Types:
    #
    # Most inputs map directly to one of ActiveRecord's column types by default (eg string_input),
    # but there are a few special cases and some simplification (:integer, :float and :decimal
    # columns all map to a single numeric_input, for example).
    #
    # * :select (a select menu for associations) - default to association names
    # * :check_boxes (a set of check_box inputs for associations) - alternative to :select has_many and has_and_belongs_to_many associations
    # * :radio (a set of radio inputs for associations) - alternative to :select belongs_to associations
    # * :time_zone (a select menu with time zones)
    # * :password (a password input) - default for :string column types with 'password' in the method name
    # * :text (a textarea) - default for :text column types
    # * :date (a date select) - default for :date column types
    # * :datetime (a date and time select) - default for :datetime and :timestamp column types
    # * :time (a time select) - default for :time column types
    # * :boolean (a checkbox) - default for :boolean column types (you can also have booleans as :select and :radio)
    # * :string (a text field) - default for :string column types
    # * :numeric (a text field, like string) - default for :integer, :float and :decimal column types
    # * :country (a select menu of country names) - requires a country_select plugin to be installed
    # * :hidden (a hidden field) - creates a hidden field (added for compatibility)
    #
    # Example:
    #
    #   <% semantic_form_for @employee do |form| %>
    #     <% form.inputs do -%>
    #       <%= form.input :name, :label => "Full Name"%>
    #       <%= form.input :manager_id, :as => :radio %>
    #       <%= form.input :hired_at, :as => :date, :label => "Date Hired" %>
    #       <%= form.input :phone, :required => false, :hint => "Eg: +1 555 1234" %>
    #     <% end %>
    #   <% end %>
    #
    def input(method, options = {})
      options[:required] = method_required?(method) unless options.key?(:required)
      options[:as]     ||= default_input_type(method)
  
      html_class = [ options[:as], (options[:required] ? :required : :optional) ]
      html_class << 'error' if @object && @object.respond_to?(:errors) && !@object.errors[method.to_sym].blank?
      html_class << method.to_s
  
      wrapper_html = options.delete(:wrapper_html) || {}
      wrapper_html[:id]  ||= generate_html_id(method)
      wrapper_html[:class] = (html_class << wrapper_html[:class]).flatten.compact.join(' ')
  
      if options[:input_html] && options[:input_html][:id]
        options[:label_html] ||= {}
        options[:label_html][:for] ||= options[:input_html][:id]
      end
  
      input_parts = inline_order.dup
      input_parts.delete(:errors) if options[:as] == :hidden
      
      list_item_content = input_parts.map do |type|
        send(:"inline_#{type}_for", method, options)
      end.compact.join("\n")
  
      return template.content_tag(:li, list_item_content, wrapper_html)
    end
    
    # Outputs a label and standard Rails text field inside the wrapper.
    def string_input(method, options)
      basic_input_helper(:text_field, :string, method, options)
    end
  
    # Outputs a label and standard Rails password field inside the wrapper.
    def password_input(method, options)
      basic_input_helper(:password_field, :password, method, options)
    end
    
    # Outputs a label and standard Rails text field inside the wrapper.
    def numeric_input(method, options)
      basic_input_helper(:text_field, :numeric, method, options)
    end
    
    # Ouputs a label and standard Rails text area inside the wrapper.
    def text_input(method, options)
      basic_input_helper(:text_area, :text, method, options)
    end
    
    # Outputs a label and a standard Rails file field inside the wrapper.
    def file_input(method, options)
      basic_input_helper(:file_field, :file, method, options)
    end
  
    # Outputs a hidden field inside the wrapper, which should be hidden with CSS.
    # Additionals options can be given and will be sent straight to hidden input
    # element.
    def hidden_input(method, options)
      self.hidden_field(method, remove_formtastic_options(options))
    end
  
    # Outputs a label and a select box containing options from the parent
    # (belongs_to, has_many, has_and_belongs_to_many) association. If an association
    # is has_many or has_and_belongs_to_many the select box will be set as multi-select
    # and size = 5
    #
    # Example (belongs_to):
    #
    #   f.input :author
    #
    #   <label for="book_author_id">Author</label>
    #   <select id="book_author_id" name="book[author_id]">
    #     <option value=""></option>
    #     <option value="1">Justin French</option>
    #     <option value="2">Jane Doe</option>
    #   </select>
    #
    # Example (has_many):
    #
    #   f.input :chapters
    #
    #   <label for="book_chapter_ids">Chapters</label>
    #   <select id="book_chapter_ids" name="book[chapter_ids]">
    #     <option value=""></option>
    #     <option value="1">Chapter 1</option>
    #     <option value="2">Chapter 2</option>
    #   </select>
    #
    # Example (has_and_belongs_to_many):
    #
    #   f.input :authors
    #
    #   <label for="book_author_ids">Authors</label>
    #   <select id="book_author_ids" name="book[author_ids]">
    #     <option value=""></option>
    #     <option value="1">Justin French</option>
    #     <option value="2">Jane Doe</option>
    #   </select>
    #
    #
    # You can customize the options available in the select by passing in a collection (an Array or 
    # Hash) through the :collection option.  If not provided, the choices are found by inferring the 
    # parent's class name from the method name and simply calling find(:all) on it 
    # (VehicleOwner.find(:all) in the example above).
    #
    # Examples:
    #
    #   f.input :author, :collection => @authors
    #   f.input :author, :collection => Author.find(:all)
    #   f.input :author, :collection => [@justin, @kate]
    #   f.input :author, :collection => {@justin.name => @justin.id, @kate.name => @kate.id}
    #   f.input :author, :collection => ["Justin", "Kate", "Amelia", "Gus", "Meg"]
    #
    # The :label_method option allows you to customize the text label inside each option tag two ways:
    #
    # * by naming the correct method to call on each object in the collection as a symbol (:name, :login, etc)
    # * by passing a Proc that will be called on each object in the collection, allowing you to use helpers or multiple model attributes together
    #
    # Examples:
    #
    #   f.input :author, :label_method => :full_name
    #   f.input :author, :label_method => :login
    #   f.input :author, :label_method => :full_name_with_post_count
    #   f.input :author, :label_method => Proc.new { |a| "#{a.name} (#{pluralize("post", a.posts.count)})" }
    #
    # The :value_method option provides the same customization of the value attribute of each option tag.
    #
    # Examples:
    #
    #   f.input :author, :value_method => :full_name
    #   f.input :author, :value_method => :login
    #   f.input :author, :value_method => Proc.new { |a| "author_#{a.login}" }
    #
    # You can pre-select a specific option value by passing in the :select option.
    # 
    # Examples:
    #  
    #   f.input :author, :selected => current_user.id
    #   f.input :author, :value_method => :login, :selected => current_user.login
    #
    # You can pass html_options to the select tag using :input_html => {}
    #
    # Examples:
    #
    #   f.input :authors, :input_html => {:size => 20, :multiple => true}
    #
    # By default, all select inputs will have a blank option at the top of the list. You can add
    # a prompt with the :prompt option, or disable the blank option with :include_blank => false.
    #
    def select_input(method, options)
      collection = find_collection_for_column(method, options)
      html_options = options.delete(:input_html) || {}
      options = set_include_blank(options)
  
      reflection = find_reflection(method)
      if reflection && [ :has_many, :has_and_belongs_to_many ].include?(reflection.macro)
        options[:include_blank]   = false
        html_options[:multiple] ||= true
        html_options[:size]     ||= 5
       end
  
      input_name = generate_association_input_name(method)
      self.label(method, options_for_label(options).merge(:input_name => input_name)) +
      self.select(input_name, collection, remove_formtastic_options(options), html_options)
    end
    alias :boolean_select_input :select_input
  
    # Outputs a timezone select input as Rails' time_zone_select helper. You
    # can give priority zones as option.
    #
    # Examples:
    #
    #   f.input :time_zone, :as => :time_zone, :priority_zones => /Australia/
    #
    def time_zone_input(method, options)
      html_options = options.delete(:input_html) || {}
  
      self.label(method, options_for_label(options)) +
      self.time_zone_select(method, options.delete(:priority_zones), remove_formtastic_options(options), html_options)
    end
  
    # Outputs a fieldset containing a legend for the label text, and an ordered list (ol) of list
    # items, one for each possible choice in the belongs_to association.  Each li contains a
    # label and a radio input.
    #
    # Example:
    #
    #   f.input :author, :as => :radio
    #
    # Output:
    #
    #   <fieldset>
    #     <legend><span>Author</span></legend>
    #     <ol>
    #       <li>
    #         <label for="book_author_id_1"><input id="book_author_id_1" name="book[author_id]" type="radio" value="1" /> Justin French</label>
    #       </li>
    #       <li>
    #         <label for="book_author_id_2"><input id="book_author_id_2" name="book[owner_id]" type="radio" value="2" /> Kate French</label>
    #       </li>
    #     </ol>
    #   </fieldset>
    #
    # You can customize the choices available in the radio button set by passing in a collection (an Array or 
    # Hash) through the :collection option.  If not provided, the choices are found by reflecting on the association
    # (Author.find(:all) in the example above).
    #
    # Examples:
    #
    #   f.input :author, :as => :radio, :collection => @authors
    #   f.input :author, :as => :radio, :collection => Author.find(:all)
    #   f.input :author, :as => :radio, :collection => [@justin, @kate]
    #   f.input :author, :collection => ["Justin", "Kate", "Amelia", "Gus", "Meg"]
    #
    # The :label_method option allows you to customize the label for each radio button two ways:
    #
    # * by naming the correct method to call on each object in the collection as a symbol (:name, :login, etc)
    # * by passing a Proc that will be called on each object in the collection, allowing you to use helpers or multiple model attributes together
    #
    # Examples:
    #
    #   f.input :author, :as => :radio, :label_method => :full_name
    #   f.input :author, :as => :radio, :label_method => :login
    #   f.input :author, :as => :radio, :label_method => :full_name_with_post_count
    #   f.input :author, :as => :radio, :label_method => Proc.new { |a| "#{a.name} (#{pluralize("post", a.posts.count)})" }
    #
    # The :value_method option provides the same customization of the value attribute of each option tag.
    #
    # Examples:
    #
    #   f.input :author, :as => :radio, :value_method => :full_name
    #   f.input :author, :as => :radio, :value_method => :login
    #   f.input :author, :as => :radio, :value_method => Proc.new { |a| "author_#{a.login}" }
    #
    # Finally, you can set :value_as_class => true if you want the li wrapper around each radio 
    # button / label combination to contain a class with the value of the radio button (useful for
    # applying specific CSS or Javascript to a particular radio button).
    def radio_input(method, options)
      collection   = find_collection_for_column(method, options)
      html_options = remove_formtastic_options(options).merge(options.delete(:input_html) || {})
  
      input_name = generate_association_input_name(method)
      value_as_class = options.delete(:value_as_class)
  
      list_item_content = collection.map do |c|
        label = c.is_a?(Array) ? c.first : c
        value = c.is_a?(Array) ? c.last  : c
  
        li_content = template.content_tag(:label,
          "#{self.radio_button(input_name, value, html_options)} #{label}",
          :for => generate_html_id(input_name, value.to_s.gsub(/\s/, '_').gsub(/\W/, '').downcase)
        )
  
        li_options = value_as_class ? { :class => value.to_s.downcase } : {}
        template.content_tag(:li, li_content, li_options)
      end
  
      field_set_and_list_wrapping_for_method(method, options, list_item_content)
    end
    alias :boolean_radio_input :radio_input
  
    # Outputs a fieldset with a legend for the method label, and a ordered list (ol) of list
    # items (li), one for each fragment for the date (year, month, day).  Each li contains a label
    # (eg "Year") and a select box.  See date_or_datetime_input for a more detailed output example.
    #
    # Some of Rails' options for select_date are supported, but not everything yet.
    def date_input(method, options)
      options = set_include_blank(options)
      date_or_datetime_input(method, options.merge(:discard_hour => true))
    end
  
  
    # Outputs a fieldset with a legend for the method label, and a ordered list (ol) of list
    # items (li), one for each fragment for the date (year, month, day, hour, min, sec).  Each li
    # contains a label (eg "Year") and a select box.  See date_or_datetime_input for a more
    # detailed output example.
    #
    # Some of Rails' options for select_date are supported, but not everything yet.
    def datetime_input(method, options)
      options = set_include_blank(options)
      date_or_datetime_input(method, options)
    end
  
  
    # Outputs a fieldset with a legend for the method label, and a ordered list (ol) of list
    # items (li), one for each fragment for the time (hour, minute, second).  Each li contains a label
    # (eg "Hour") and a select box.  See date_or_datetime_input for a more detailed output example.
    #
    # Some of Rails' options for select_time are supported, but not everything yet.
    def time_input(method, options)
      options = set_include_blank(options)
      date_or_datetime_input(method, options.merge(:discard_year => true, :discard_month => true, :discard_day => true))
    end
  
  
    # <fieldset>
    #   <legend>Created At</legend>
    #   <ol>
    #     <li>
    #       <label for="user_created_at_1i">Year</label>
    #       <select id="user_created_at_1i" name="user[created_at(1i)]">
    #         <option value="2003">2003</option>
    #         ...
    #         <option value="2013">2013</option>
    #       </select>
    #     </li>
    #     <li>
    #       <label for="user_created_at_2i">Month</label>
    #       <select id="user_created_at_2i" name="user[created_at(2i)]">
    #         <option value="1">January</option>
    #         ...
    #         <option value="12">December</option>
    #       </select>
    #     </li>
    #     <li>
    #       <label for="user_created_at_3i">Day</label>
    #       <select id="user_created_at_3i" name="user[created_at(3i)]">
    #         <option value="1">1</option>
    #         ...
    #         <option value="31">31</option>
    #       </select>
    #     </li>
    #   </ol>
    # </fieldset>
    #
    # This is an absolute abomination, but so is the official Rails select_date().
    #
    def date_or_datetime_input(method, options)
      position = { :year => 1, :month => 2, :day => 3, :hour => 4, :minute => 5, :second => 6 }
      i18n_date_order = I18n.translate(:'date.order').is_a?(Array) ? I18n.translate(:'date.order') : nil
      inputs   = options.delete(:order) || i18n_date_order || [:year, :month, :day]
  
      time_inputs = [:hour, :minute]
      time_inputs << [:second] if options[:include_seconds]
  
      list_items_capture = ""
      hidden_fields_capture = ""
  
      # Gets the datetime object. It can be a Fixnum, Date or Time, or nil.
      datetime     = @object ? @object.send(method) : nil
      html_options = options.delete(:input_html) || {}
  
      (inputs + time_inputs).each do |input|
        html_id    = generate_html_id(method, "#{position[input]}i")
        field_name = "#{method}(#{position[input]}i)"
        if options["discard_#{input}".intern]
          break if time_inputs.include?(input)
          
          hidden_value = datetime.respond_to?(input) ? datetime.send(input) : datetime
          hidden_fields_capture << template.hidden_field_tag("#{@object_name}[#{field_name}]", (hidden_value || 1), :id => html_id)
        else
          opts = remove_formtastic_options(options).merge(:prefix => @object_name, :field_name => field_name)
          item_label_text = I18n.t(input.to_s, :default => input.to_s.humanize, :scope => [:datetime, :prompts])
  
          list_items_capture << template.content_tag(:li,
            template.content_tag(:label, item_label_text, :for => html_id) +
            template.send("select_#{input}".intern, datetime, opts, html_options.merge(:id => html_id))
          )
        end
      end
  
      hidden_fields_capture + field_set_and_list_wrapping_for_method(method, options, list_items_capture)
    end
  
  
    # Outputs a fieldset containing a legend for the label text, and an ordered list (ol) of list
    # items, one for each possible choice in the belongs_to association.  Each li contains a
    # label and a check_box input.
    #
    # This is an alternative for has many and has and belongs to many associations.
    #
    # Example:
    #
    #   f.input :author, :as => :check_boxes
    #
    # Output:
    #
    #   <fieldset>
    #     <legend><span>Authors</span></legend>
    #     <ol>
    #       <li>
    #         <input type="hidden" name="book[author_id][1]" value="">
    #         <label for="book_author_id_1"><input id="book_author_id_1" name="book[author_id][1]" type="checkbox" value="1" /> Justin French</label>
    #       </li>
    #       <li>
    #         <input type="hidden" name="book[author_id][2]" value="">
    #         <label for="book_author_id_2"><input id="book_author_id_2" name="book[owner_id][2]" type="checkbox" value="2" /> Kate French</label>
    #       </li>
    #     </ol>
    #   </fieldset>
    #
    # Notice that the value of the checkbox is the same as the id and the hidden
    # field has empty value. You can override the hidden field value using the
    # unchecked_value option.
    #
    # You can customize the options available in the set by passing in a collection (Array) of
    # ActiveRecord objects through the :collection option.  If not provided, the choices are found
    # by inferring the parent's class name from the method name and simply calling find(:all) on
    # it (Author.find(:all) in the example above).
    #
    # Examples:
    #
    #   f.input :author, :as => :check_boxes, :collection => @authors
    #   f.input :author, :as => :check_boxes, :collection => Author.find(:all)
    #   f.input :author, :as => :check_boxes, :collection => [@justin, @kate]
    #
    # The :label_method option allows you to customize the label for each checkbox two ways:
    #
    # * by naming the correct method to call on each object in the collection as a symbol (:name, :login, etc)
    # * by passing a Proc that will be called on each object in the collection, allowing you to use helpers or multiple model attributes together
    #
    # Examples:
    #
    #   f.input :author, :as => :check_boxes, :label_method => :full_name
    #   f.input :author, :as => :check_boxes, :label_method => :login
    #   f.input :author, :as => :check_boxes, :label_method => :full_name_with_post_count
    #   f.input :author, :as => :check_boxes, :label_method => Proc.new { |a| "#{a.name} (#{pluralize("post", a.posts.count)})" }
    #
    # The :value_method option provides the same customization of the value attribute of each checkbox input tag.
    #
    # Examples:
    #
    #   f.input :author, :as => :check_boxes, :value_method => :full_name
    #   f.input :author, :as => :check_boxes, :value_method => :login
    #   f.input :author, :as => :check_boxes, :value_method => Proc.new { |a| "author_#{a.login}" }
    #
    # Finally, you can set :value_as_class => true if you want the li wrapper around each checkbox / label 
    # combination to contain a class with the value of the radio button (useful for applying specific 
    # CSS or Javascript to a particular checkbox).
    def check_boxes_input(method, options)
      collection = find_collection_for_column(method, options)
      html_options = options.delete(:input_html) || {}
  
      input_name      = generate_association_input_name(method)
      value_as_class  = options.delete(:value_as_class)
      unchecked_value = options.delete(:unchecked_value) || ''
      html_options    = { :name => "#{@object_name}[#{input_name}][]" }.merge(html_options)
  
      list_item_content = collection.map do |c|
        label = c.is_a?(Array) ? c.first : c
        value = c.is_a?(Array) ? c.last : c
  
        html_options.merge!(:id => generate_html_id(input_name, value.to_s.gsub(/\s/, '_').gsub(/\W/, '').downcase))
  
        li_content = template.content_tag(:label,
          "#{self.check_box(input_name, html_options, value, unchecked_value)} #{label}",
          :for => html_options[:id]
        )
  
        li_options = value_as_class ? { :class => value.to_s.downcase } : {}
        template.content_tag(:li, li_content, li_options)
      end
  
      field_set_and_list_wrapping_for_method(method, options, list_item_content)
    end
    
    
    # Outputs a country select input, wrapping around a regular country_select helper. 
    # Rails doesn't come with a country_select helper by default any more, so you'll need to install
    # the "official" plugin, or, if you wish, any other country_select plugin that behaves in the
    # same way.
    #
    # The Rails plugin iso-3166-country-select plugin can be found "here":http://github.com/rails/iso-3166-country-select.
    #
    # By default, Formtastic includes a handfull of english-speaking countries as "priority counties", 
    # which you can change to suit your market and user base (see README for more info on config).
    #
    # Examples:
    #   f.input :location, :as => :country # use Formtastic::SemanticFormBuilder.priority_countries array for the priority countries
    #   f.input :location, :as => :country, :priority_countries => /Australia/ # set your own
    def country_input(method, options)
      raise "To use the :country input, please install a country_select plugin, like this one: http://github.com/rails/iso-3166-country-select" unless self.respond_to?(:country_select)
      
      html_options = options.delete(:input_html) || {}
      top_countries = options.delete(:priority_countries) || priority_countries
  
      self.label(method, options_for_label(options)) +
      self.country_select(method, top_countries, remove_formtastic_options(options), html_options)
    end
    
  
    # Outputs a label containing a checkbox and the label text. The label defaults
    # to the column name (method name) and can be altered with the :label option.
    # :checked_value and :unchecked_value options are also available.
    def boolean_input(method, options)
      html_options = options.delete(:input_html) || {}
  
      input = self.check_box(method, remove_formtastic_options(options).merge(html_options),
                             options.delete(:checked_value) || '1', options.delete(:unchecked_value) || '0')
      options = options_for_label(options)
      
      # the label() method will insert this nested input into the label at the last minute
      options[:label_prefix_for_nested_input] = input
      
      self.label(method, options)
    end

    
    protected
    
    # Determins if the attribute (eg :title) should be considered required or not.
    #
    # * if the :required option was provided in the options hash, the true/false value will be
    #   returned immediately, allowing the view to override any guesswork that follows:
    #
    # * if the :required option isn't provided in the options hash, and the ValidationReflection
    #   plugin is installed (http://github.com/redinger/validation_reflection), true is returned
    #   if the validates_presence_of macro has been used in the class for this attribute, or false
    #   otherwise.
    #
    # * if the :required option isn't provided, and the plugin isn't available, the value of the
    #   configuration option all_fields_required_by_default is used.
    def method_required?(attribute) #:nodoc:
      if @object && @object.class.respond_to?(:reflect_on_validations_for)
        attribute_sym = attribute.to_s.sub(/_id$/, '').to_sym
        
        @object.class.reflect_on_validations_for(attribute_sym).any? do |validation|
          validation.macro == :validates_presence_of &&
          validation.name == attribute_sym &&
          (validation.options.present? ? options_require_validation?(validation.options) : true)
        end
      else
        all_fields_required_by_default
      end
    end
    
    # Determines whether the given options evaluate to true
    def options_require_validation?(options) #nodoc
      if_condition = !options[:if].nil?
      condition = if_condition ? options[:if] : options[:unless]
  
      condition = if condition.respond_to?(:call)
                    condition.call(@object)
                  elsif condition.is_a?(::Symbol) && @object.respond_to?(condition)
                    @object.send(condition)
                  else
                    condition
                  end
  
      if_condition ? !!condition : !condition
    end
    
    # Remove any Formtastic-specific options before passing the down options.
    def remove_formtastic_options(options)
      options.except(:value_method, :label_method, :collection, :required, :label,
                     :as, :hint, :input_html, :label_html, :value_as_class)
    end
    
    # Helper method to extract common patterns in a lot of the simpler inputs we have, like string.
    def basic_input_helper(form_helper_method, type, method, options)
      html_options = options.delete(:input_html) || {}
      html_options = default_string_options(method, type).merge(html_options) if [:numeric, :string, :password].include?(type)
  
      self.label(method, options_for_label(options)) +
      self.send(form_helper_method, method, html_options)
    end
    
    # Also generates a fieldset and an ordered list but with label based in
    # method. This methods is currently used by radio and datetime inputs.
    def field_set_and_list_wrapping_for_method(method, options, contents)
      contents = contents.join if contents.respond_to?(:join)
  
      template.content_tag(:fieldset,
        %{<legend>#{self.label(method, options_for_label(options).merge!(:as_span => true))}</legend>} +
        template.content_tag(:ol, contents)
      )
    end
    
    # For methods that have a database column, take a best guess as to what the input method
    # should be.  In most cases, it will just return the column type (eg :string), but for special
    # cases it will simplify (like the case of :integer, :float & :decimal to :numeric), or do
    # something different (like :password and :select).
    #
    # If there is no column for the method (eg "virtual columns" with an attr_accessor), the
    # default is a :string, a similar behaviour to Rails' scaffolding.
    def default_input_type(method) #:nodoc:
      column = @object.column_for_attribute(method) if @object.respond_to?(:column_for_attribute)
  
      if column
        # handle the special cases where the column type doesn't map to an input method
        return :time_zone if column.type == :string && method.to_s =~ /time_zone/
        return :select    if column.type == :integer && method.to_s =~ /_id$/
        return :datetime  if column.type == :timestamp
        return :numeric   if [:integer, :float, :decimal].include?(column.type)
        return :password  if column.type == :string && method.to_s =~ /password/
        return :country   if column.type == :string && method.to_s =~ /country/
  
        # otherwise assume the input name will be the same as the column type (eg string_input)
        return column.type
      else
        if @object
          return :select if find_reflection(method)
  
          file = @object.send(method) if @object.respond_to?(method)
          return :file   if file && file_methods.any? { |m| file.respond_to?(m) }
        end
  
        return :password if method.to_s =~ /password/
        return :string
      end
    end
    
    # Used by select and radio inputs. The collection can be retrieved by
    # three ways:
    #
    # * Explicitly provided through :collection
    # * Retrivied through an association
    # * Or a boolean column, which will generate a localized { "Yes" => true, "No" => false } hash.
    #
    # If the collection is not a hash or an array of strings, fixnums or arrays,
    # we use label_method and value_method to retreive an array with the
    # appropriate label and value.
    def find_collection_for_column(column, options)
      reflection = find_reflection(column)
  
      collection = if options[:collection]
        options.delete(:collection)
      elsif reflection
        reflection.klass.find(:all)
      else
        create_boolean_collection(options)
      end
  
      collection = collection.to_a if collection.is_a?(Hash)
  
      # Return if we have an Array of strings, fixnums or arrays
      return collection if collection.instance_of?(Array) &&
                           [Array, Fixnum, String, Symbol].include?(collection.first.class)
  
      label = options.delete(:label_method) || detect_label_method(collection)
      value = options.delete(:value_method) || :id
  
      collection.map { |o| [send_or_call(label, o), send_or_call(value, o)] }
    end
    
    # Detected the label collection method when none is supplied using the
    # values set in collection_label_methods.
    def detect_label_method(collection) #:nodoc:
      collection_label_methods.detect { |m| collection.first.respond_to?(m) }
    end
  
    # Returns a hash to be used by radio and select inputs when a boolean field
    # is provided.
    def create_boolean_collection(options)
      options[:true] ||= I18n.t('yes', :default => 'Yes', :scope => [:formtastic])
      options[:false] ||= I18n.t('no', :default => 'No', :scope => [:formtastic])
      options[:value_as_class] = true unless options.key?(:value_as_class)
  
      [ [ options.delete(:true), true], [ options.delete(:false), false ] ]
    end
    
    # Used by association inputs (select, radio) to generate the name that should
    # be used for the input
    #
    #   belongs_to :author; f.input :author; will generate 'author_id'
    #   belongs_to :entity, :foreign_key = :owner_id; f.input :author; will generate 'owner_id'
    #   has_many :authors; f.input :authors; will generate 'author_ids'
    #   has_and_belongs_to_many will act like has_many
    def generate_association_input_name(method)
      if reflection = find_reflection(method)
        if [:has_and_belongs_to_many, :has_many].include?(reflection.macro)
          "#{method.to_s.singularize}_ids"
        else
          reflection.options[:foreign_key] || "#{method}_id"
        end
      else
        method
      end
    end
  
    # If an association method is passed in (f.input :author) try to find the
    # reflection object.
    def find_reflection(method)
      @object.class.reflect_on_association(method) if @object.class.respond_to?(:reflect_on_association)
    end
  
    # Generates default_string_options by retrieving column information from
    # the database.
    def default_string_options(method, type) #:nodoc:
      column = @object.column_for_attribute(method) if @object.respond_to?(:column_for_attribute)
  
      if type == :numeric || column.nil? || column.limit.nil?
        { :size => default_text_field_size }
      else
        { :maxlength => column.limit, :size => [column.limit, default_text_field_size].min }
      end
    end
    
    # Generate the html id for the li tag.
    # It takes into account options[:index] and @auto_index to generate li
    # elements with appropriate index scope. It also sanitizes the object
    # and method names.
    def generate_html_id(method_name, value='input')
      if options.has_key?(:index)
        index = "_#{options[:index]}"
      elsif defined?(@auto_index)
        index = "_#{@auto_index}"
      else
        index = ""
      end
      sanitized_method_name = method_name.to_s.gsub(/[\?\/\-]$/, '')
      
      "#{sanitized_object_name}#{index}_#{sanitized_method_name}_#{value}"
    end
    
    # Gets the nested_child_index value from the parent builder. In Rails 2.3
    # it always returns a fixnum. In next versions it returns a hash with each
    # association that the parent builds.
    def parent_child_index(parent)
      duck = parent[:builder].instance_variable_get('@nested_child_index')
  
      if duck.is_a?(Hash)
        child = parent[:for]
        child = child.first if child.respond_to?(:first)
        duck[child].to_i + 1
      else
        duck.to_i + 1
      end
    end
    
    def sanitized_object_name
      @sanitized_object_name ||= @object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
    end
  
    def humanized_attribute_name(method)
      if @object && @object.class.respond_to?(:human_attribute_name)
        @object.class.human_attribute_name(method.to_s)
      else
        method.to_s.send(label_str_method)
      end
    end
  
  end
end