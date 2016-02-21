require 'spec_helper'

describe "trash/index.html.haml" do
  let!(:instance) { create(:instance) }
  let!(:suite_1) { create(:suite, instance: instance) }
  let!(:suite_2) { create(:suite, instance: instance) }
  let!(:evaluation) { create(:suite_evaluation, suite: suite_1) }
  before(:each) do
    suite_1.destroy
    suite_2.destroy
    evaluation.destroy
    assign(:suites, [suite_1, suite_2])
    assign(:evaluations, [evaluation])
    render
  end

  subject { rendered }
  it      { should have_selector(".suites-table tbody tr", count: 2) }
  it      { should have_selector(".evaluations-table tbody tr", count: 1) }
end
