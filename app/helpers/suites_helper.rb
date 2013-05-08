module SuitesHelper

  # Generates a sorted list of the entries that
  # should appear in the suite calendar
  def calendar_entries(suite)
    (
      suite.evaluations +
        suite.meetings
    ).sort_by(&:date)
  end

  # Returns true if the user is currently
  # working within a suite
  def working_with_suite?
  end

  # Returns true if the user is currently
  # working with a suite template
  def working_with_suite_template?
  end
end
