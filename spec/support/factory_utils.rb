module FactoryUtils
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
    attributes_for(:"invalid_#{model}").keep_if { |k, _| accessible_attrs.include?(k.to_s) }
  end
end
