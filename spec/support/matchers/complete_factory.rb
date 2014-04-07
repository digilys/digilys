def add_be_a_complete(name, klass, excluded_attributes, excluded_associations)
  RSpec::Matchers.define :"be_a_complete_#{name}" do
    match do |model|
      @blanks = []
      required_attributes = klass.attribute_names - excluded_attributes
      required_associations = klass.reflect_on_all_associations.collect(&:name) - excluded_associations

      required_attributes.each do |attr|
        @blanks << attr if model.send(attr).blank?
      end
      required_associations.each do |assoc|
        @blanks << assoc if model.send(assoc).blank?
      end

      @blanks.blank?
    end

    failure_message_for_should do |model|
      "expected #{model.inspect} to have the following set to non blank values: #{@blanks.join(", ")}"
    end
  end
end

add_be_a_complete(:suite_template, Suite, [
  "template_id",         # Do not require templates to belong to other templates
  "generic_evaluations", # Generic evaluations are only relevant for the color table
  "student_data",        # Student data is only relevant for the color table
], [
  :roles,        # Roles are not copied from templates
  :versions,     # PaperTrail is not needed
  :template,     # Do not require templates to belong to other templates
  :children,     # A new template should not have children
  :users,        # Users not required for a template
  :activities,   # Templates do not have activities
  :participants, # Templates do not have participants
  :students,     # dito
  :groups,       # dito
  :results,      # dito
  :color_table,  # Templates do not have color tables
  :table_states, # dito
])

add_be_a_complete(:suite_evaluation, Evaluation, [
  "instance_id",   # The instance is on the suite for suite evaluations
  "value_aliases", # It's a numeric template, thus no value aliases
  "imported",      # Suite evaluations are not imported
  "date",          # If it's a suite template, the date is blank
], [
  :versions,                # PaperTrail is not needed
  :instance,                # The instance is on the suite for suite evaluations])
  :children,                # Suite evaluations have no children
  :users,                   # Not relevant when creating suite evaluations
  :evaluation_participants, # dito
  :suite_participants,      # Belongs to the suite
  :results,                 # Not relevant for creation
  :students,                # dito
  :color_tables,            # If it's a suite template, there is no color table
])

add_be_a_complete(:evaluation_template, Evaluation, [
  "suite_id",          # Templates have no suite
  "date",              # Templates have no date
  "template_id",       # Don't require that a complete template should belong to another template
  "value_aliases",     # It's a numeric template, thus no value aliases
  "series_id",         # Templates do not belong to series
  "is_series_current", # dito
], [
  :versions,                # PaperTrail is not needed
  :template,                # Don't require that a complete template should belong to another template
  :children,                # A new template should not have children
  :evaluation_participants, # Participants are part of the suite
  :suite_participants,      # dito
  :users,                   # Users not required for a template
  :color_tables,            # Templates have no color tables
  :suite,                   # Templates have no suite
  :series,                  # Templates do not belong to series
  :results,                 # Templates have no results
  :students,                # dito
])

add_be_a_complete(:meeting, Meeting, [
  "completed", # Meetings are completed later
  "notes",     # dito
], [
  :versions,   # PaperTrail is not needed
  :activities, # Activites are added upon completion
])
