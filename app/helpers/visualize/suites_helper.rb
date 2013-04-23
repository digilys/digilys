module Visualize::SuitesHelper
  def result_color_class(result)
    if result.blank?
      return ""
    else
      return "result-#{result.color}"
    end
  end
end
