module SuitesHelper

  # Generates a sorted list of the entries that
  # should appear in the suite calendar
  def calendar_entries(suite)
    open, closed = (suite.evaluations + suite.meetings).
      sort_by(&:date).
      partition { |e| !e.completed? }

    { open: open, closed: closed }
  end

  # Returns true if the user is currently working within a suite
  def working_with_suite?(suite, evaluation)
    @working_with_suite ||= suite && !suite.is_template? ||
      (params.has_key?(:suite_id) && !params?(controller: "students")) ||
      params?(controller: "suites") && !suite.try(:is_template?) ||
      evaluation && !evaluation.suite_id.blank?
  end

  # Returns true if the user is currently working with a suite template
  def working_with_suite_template?(suite)
    @working_with_suite_template ||= params?(controller: "template/suites") ||
      suite && suite.is_template?
  end

  def result_color_class(result_or_value, evaluation = nil)
    case result_or_value
    when Result
      return result_or_value.absent ? "" : "result-#{result_or_value.color}"
    when Numeric
      return "result-#{evaluation.color_for(result_or_value)}"
    else
      return ""
    end
  end

  def format_range(range)
    case range
    when Range
      if range.min < range.max
        "#{range.min} &ndash; #{range.max}".html_safe
      else
        range.min
      end
    else
      range
    end
  end

  # Displays an information message for closed suites
  def closed_suite_message(suite)
    if suite && suite.closed?
      change_status_paragraph = if can?(:change_status, suite)
        content_tag(
          :p,
          link_to(t(:"suites.closed_suite_message_change_status_html"), confirm_status_change_suite_path(suite))
        )
      else
        "".html_safe
      end

      content_tag(
        :div,
        content_tag(
          :p,
          t(:"suites.closed_suite_message_html")
        ) + change_status_paragraph,
        class: "alert alert-block alert-warning"
      )
    end
  end
end
