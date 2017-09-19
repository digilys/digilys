require "spec_helper"

feature "Creating suites from templates" do
  given!(:template) { create(:complete_suite_template, instance: admin.active_instance) }
  given!(:admin)    { create(:admin, password: "password") }

  scenario "Creating a new suite from a template" do
    # Log in
    visit "/authenticate/sign_in"
    within "#new_user" do
      fill_in "user_email",    with: admin.email
      fill_in "user_password", with: "password"
      find("[name=commit]").click
    end

    visit "/suites/new"

    within "#new_suite_from_template" do
      find("#suite_template_id").set template.id
      find("[name=commit]").click
    end

    within "#new_suite" do
      expect(find("#suite_template_id").value).to eq "#{template.id}"

      fill_in "suite_name",                          with: "Suite name"
      fill_in "suite_evaluations_attributes_0_date", with: Date.today.to_s
      fill_in "suite_meetings_attributes_0_date",    with: Date.tomorrow.to_s

      find(".form-actions").find("[name=commit]").click
    end

    suite = Suite.order(:id).last
    expect(page.current_path).to eq "/suites/#{suite.id}"

    expect(suite.template_id).to eq template.id
    expect(suite.name).to        eq "Suite name"

    expect(suite.evaluations.first.date).to eq Date.today
    expect(suite.meetings.first.date).to    eq Date.tomorrow

    expect(suite).to be_a_complete_copy_of(template).ignore_attributes(
      Suite => [
        :name,              # Changed above
        :template_id,       # Checked above
        :is_template,       # Not relevant
      ],
      Evaluation => [
        :suite_id,          # The evaluations' suite id will differ
        :date,              # The template's evaluations do not have dates
        :series_id,         # The evaluations' series id will differ...
        :is_series_current, # ... as will the current flag
        :status,
        :sort,
      ],
      Meeting => [
        :suite_id, # The meetings' suite id will differ
        :date,     # The template's meetings do not have dates
      ],
      Series => [
        :suite_id, # The series' suite id will differ
      ]
    ).ignore_associations(
      Suite => [
        :roles,             # Roles are irrelevant
        :children,          # Only the template has children
        :users,             # Users are irrelevant for templkates
        :color_table,       # Only the non template suite has a color table
      ],
      Evaluation => [
        :color_tables,      # The evaluations' color tables will differ
        :base_tags,         # Checked using category_list
        :taggings,          # Checked using category_list
        :categories,        # Checked using category_list
        :category_taggings, # Checked using category_list
      ]
    )
  end
end
