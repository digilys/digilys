require "spec_helper"

feature "Creating evaluations from templates" do
  given(:admin)    { create(:admin, password: "password") }
  given(:instance) { admin.active_instance }
  given(:template) { create(:complete_evaluation_template, instance: instance) }
  given(:suite)    { create(:suite, instance: instance)}

  scenario "Creating a new evaluation from a template" do
    # Log in
    visit "/authenticate/sign_in"
    within "#new_user" do
      fill_in "user_email",    with: admin.email
      fill_in "user_password", with: "password"
      find("[name=commit]").click
    end

    visit "/suites/#{suite.id}/evaluations/new"

    within ".select-evaluation-template-form" do
      find("#evaluation_template_id").set template.id
      find("[name=commit]").click
    end

    within "#evaluation-form" do
      expect(find("#evaluation_template_id").value).to eq "#{template.id}"

      fill_in "evaluation_date", with: Date.today.to_s
      find(".form-actions").find("[name=commit]").click
    end

    evaluation = Evaluation.order(:id).last
    expect(page.current_path).to eq "/evaluations/#{evaluation.id}"

    expect(evaluation.template_id).to eq template.id
    expect(evaluation.date).to        eq Date.today
    expect(evaluation.type).to        eq "suite"
    expect(evaluation.suite).to       eq suite

    expect(evaluation).to be_a_complete_copy_of(template).ignore_attributes(
      Evaluation => [
        :suite_id,    # The template has no suite
        :date,        # The template has no date
        :template_id, # Is checked above
        :type,        # Differs, one is suite, one is
        :instance_id, # The suite evaluation has no instance
        :imported,    # Suite templates cannot be imported
      ]
    ).ignore_associations(
      Evaluation => [
        :children,          # Suite evaluations have no children
        :base_tags,         # Checked using category_list
        :taggings,          # Checked using category_list
        :categories,        # Checked using category_list
        :category_taggings, # Checked using category_list
        :color_tables,      # Evaluation templates do not belong to color tables
      ]
    )
  end
end
