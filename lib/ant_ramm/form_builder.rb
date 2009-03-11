module AntRamm
  class FormBuilder < ActionView::Helpers::FormBuilder
  #####################################
  # Generic Helpers
    # Define methods for basic fields
    %w[text_field collection_select password_field text_area country_select 
          date_select select check_box file_field].each do |method_name|
      define_method(method_name) do |field_name, *args|
        field_wrapper(field_name, super, *args)
      end
    end

    # Wrapper because it references the default_form_helper instead of the current one
    def fields_for(record_or_name_or_array, *args, &block)
      options = args.extract_options!.merge(:builder => self.class)
      super(record_or_name_or_array, *(args + [options]), &block)
    end

    def field_set(legend = nil, &block)
      @template.field_set_tag(legend) do
        @template.content_tag(:ol, @template.capture(&block))
      end
    end
  
    def help_field(text = nil, *args, &block)
      @template.content_tag(:li, :class => 'help') do
        returning [] do |out|
          out << text unless text.nil?
          out << @template.capture(&block) unless block.nil?
        end.join("\n")
      end
    end
  
    # Unifies the controls at the bottom of the form
    def edit_tools(*args, &block)
      options = args.extract_options!.reverse_merge(:submit_text => 'Go', :cancel_text => 'Cancel', :cancel_url => object,
                                                    :show_cancel => true)
      @template.content_tag(:div, :class => 'edit-tools') do
        returning [] do |out|
          out << @template.capture(&block) unless block.nil?
          out << @template.link_to(options[:cancel_text], options[:cancel_url]) if options[:show_cancel]
          out << submit(options[:submit_text])
        end.join("\n")
      end
    end

  private
    def field_wrapper(field_name, content, *args)
      options = object.errors.invalid?(field_name) ? {:class => "field-with-errors"} : {}
      @template.content_tag(:li, [field_label(field_name, *args), content, errors_for_field(field_name)].join("\n"), options)
    end

    def errors_for_field(field_name)
      return "" unless object.errors.invalid?(field_name)
      @template.content_tag(:ul, :class => 'inline-error-messages') do
        object.errors.on(field_name).map do |err|
          @template.content_tag(:li, err)
        end.join("\n")
      end
    end

    def field_error(field_name)
      if object.errors.invalid? field_name
        @template.content_tag(:span, [object.errors.on(field_name)].flatten.first.sub(/^\^/, ''), :class => 'error_message')
      else
        ''
      end
    end

    def field_label(field_name, *args)
      options = args.extract_options!
      options.reverse_merge!(:required => field_required?(field_name))
      options[:label] = (options[:label].blank? ? nil : options[:label].to_s) || field_name.to_s.humanize
      options[:label] = "#{@template.content_tag(:em, "*")} " + options[:label] if options[:required]
      options[:label_class] = "required" if options[:required]
      label(field_name, options[:label], :class => options[:label_class])
    end

    def field_required?(field_name)
      object.class.reflect_on_validations_for(field_name).detect do |obj|
        (obj.macro == :validates_presence_of) || 
        (obj.macro == :validates_length_of && ( (obj.options[:within] && !obj.options[:within].include?(0)) ||
                                                (obj.options[:minimum] && obj.options[:minimum] > 0) 
                                              ) )
      end
    end

    def objectify_options(options)
      super.except(:label, :required, :label_class)
    end
  # End Generic Helpers
  #####################################

  #####################################
  # New Custom Helpers
  public
    # Could this be altered for nested models?
    # Used image selection when editing an artefact
    def thumb_with_remove_and_default(image, remove_method = :remove_images, default_method = :default_image_id, *args)
      @template.content_tag(:li, :class => "ai-wrapper") do
        @template.content_tag(:div, @template.link_to( @template.image_tag(image.url), image.url(:large), :class => "lightbox") ) +
        @template.content_tag(:div) do
          @template.check_box_tag("#{object_name}[#{remove_method}][]", image.id) + " remove"
        end +
        @template.content_tag(:div) do
          radio_button(default_method, image.id) + " default"
        end
      end
    end
  
    def date_month_year_select(field_name)
      date_select field_name, {:start_year => 1960, :end_year => Date.today.year, :discard_day => true, :order => [:month, :year]}
    end
  
    def date_dob_select(field_name)
      date_select field_name, :start_year => 1900, :end_year => Date.today.year - 1, :order => [:day, :month, :year], 
                              :include_blank => true
    end
  
  # End New Custom Helpers
  #####################################
  end
end

