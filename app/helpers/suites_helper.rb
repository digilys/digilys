module SuitesHelper

  # Generates a sorted list of the entries that
  # should appear in the suite calendar
  def calendar_entries(suite)
    (
      suite.evaluations +
        suite.meetings
    ).sort_by(&:date)
  end
end
