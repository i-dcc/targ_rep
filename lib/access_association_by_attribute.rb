# encoding: utf-8

module AccessAssociationByAttribute
  # Some behaviour may be undefined if the attribute of the association can be blank
  def access_association_by_attribute(association_name, attribute, options = {})
    options.symbolize_keys!

    association_class = reflections[association_name].klass

    if ! options[:full_alias].blank?
      virtual_attribute = options[:full_alias]
    elsif ! options[:attribute_alias].blank?
      virtual_attribute = "#{association_name}_#{options[:attribute_alias]}"
    else
      virtual_attribute = "#{association_name}_#{attribute}"
    end

    if ! instance_methods.include?(:reload_without_aaba)
      alias_method :reload_without_aaba, :reload

      define_method :reload do |*args|
        retval = reload_without_aaba(*args)
        @aaba_what_changed = []
        return retval
      end
    end

    define_method virtual_attribute do
      @aaba_what_changed ||= []
      if instance_variable_defined?("@#{virtual_attribute}") and @aaba_what_changed.include?(virtual_attribute)
        return instance_variable_get("@#{virtual_attribute}")
      else
        new_value = self.send(association_name).try(:send, attribute)
        instance_variable_set("@#{virtual_attribute}", new_value)
        return new_value
      end
    end

    define_method "#{virtual_attribute}=" do |value|
      @aaba_what_changed ||= []
      @aaba_what_changed.push virtual_attribute

      instance_variable_set("@#{virtual_attribute}_errors_", nil)
      instance_variable_set("@#{virtual_attribute}", value)

      if value.blank?
        self.send("#{association_name}=", nil)
        return
      end

      if !value.respond_to?(:to_str)
        instance_variable_set("@#{virtual_attribute}_errors_", "'#{value}' is invalid")
        return
      end

      new_object = association_class.send("find_by_#{attribute}", value)
      if !new_object
        instance_variable_set("@#{virtual_attribute}_errors_", "'#{value}' does not exist")
        return
      end

      self.send("#{association_name}=", new_object)
    end

    define_method "#{virtual_attribute}_validation" do
      @aaba_what_changed ||= []
      errors = instance_variable_get("@#{virtual_attribute}_errors_")
      if errors and @aaba_what_changed.include?(virtual_attribute)
        self.errors.add(virtual_attribute, errors)
      end
    end

    validate "#{virtual_attribute}_validation"

  end
end
