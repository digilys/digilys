module Visualize::SuitesHelper
  def result_color_class(result)
    if result.blank?
      return ""
    else
      return "result-#{result.color}"
    end
  end

  def format_range(range)
    case range
    when Range
      "#{range.min} &ndash; #{range.max}".html_safe
    else
      range
    end
  end
end
