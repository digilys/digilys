module FactoryUtils
  # Generates parameters for a model that will result
  # in the model being valid. For use when sending
  # parameters to a controller action that creates/updates
  # a model.
  def valid_parameters_for(model)
    accessible_attrs = model.to_s.classify.constantize.accessible_attributes
    return filter_parameters(model, accessible_attrs)
  end

  # Generates parameters for a model that will result
  # in the model being invalid. For use when sending
  # parameters to a controller action that creates/updates
  # a model.
  #
  # This requires that a factory named :invalid_{model_name}
  # is defined with parameters that generate an invalid
  # model.
  def invalid_parameters_for(model)
    accessible_attrs = model.to_s.classify.constantize.accessible_attributes
    return filter_parameters(:"invalid_#{model}", accessible_attrs)
  end

  private

  def required?(obj, attr)
    target = (obj.class == Class) ? obj : obj.class
    target.validators_on(attribute).map(&:class).include?(
          ActiveModel::Validations::PresenceValidator)
  end

  def filter_parameters(model, accessible_attrs)
    parameters = attributes_for(model).merge build(model).attributes

    # Remove attributes that are not accessible and
    # convert active record values to ids
    parameters = parameters.inject({}) do |h, (k,v)|
      if accessible_attrs.include?(k.to_s)
        if v.is_a?(ActiveRecord::Base)
          h[:"#{k}_id"] = v.id
        else
          h[k] = v
        end
      end

      h
    end
  end

end
