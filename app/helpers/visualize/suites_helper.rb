module Visualize::SuitesHelper
  def result_color_class(result_or_value, evaluation = nil)
    case result_or_value
    when Result
      return "result-#{result_or_value.color}"
    when Numeric
      return "result-#{evaluation.color_for(result_or_value)}"
    else
      return ""
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
