require "spec_helper"

describe "index/index" do
  let(:suites)      { nil }
  let(:meetings)    { nil }
  let(:evaluations) { nil }
  let(:activities)  { nil }

  before(:each) do
    assign(:suites,      suites)
    assign(:meetings,    meetings)
    assign(:evaluations, evaluations)
    assign(:activities,  activities)
    render
  end
  subject { rendered }
  it      { should_not have_selector(".dashboard-table") }

  context "with suites" do
    let(:suites) { create_list(:suite, 2) }
    it           { should have_selector(".dashboard-table tbody tr", count: 2)}
  end
  context "with evaluations" do
    let(:evaluations) { { upcoming: create_list(:suite_evaluation, 2), overdue: create_list(:suite_evaluation, 2) } }
    it                { should have_selector(".dashboard-table tbody tr", count: 6)}
    it                { should have_selector(".dashboard-table tbody th", count: 2)}
  end
  context "with activities" do
    let(:activities) { [ create(:activity, end_date: Date.yesterday, status: :open), create(:activity) ] }
    it               { should have_selector(".dashboard-table tbody tr",   count: 2)}
    it               { should have_selector(".dashboard-table td.overdue", count: 1)}
  end
end
