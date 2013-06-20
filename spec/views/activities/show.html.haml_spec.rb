require "spec_helper"

describe "activities/show" do
  let(:activity) { create(:activity,
    status:     :open,
    start_date: nil,
    end_date:   nil,
    meeting:    nil,
    users:      [],
    groups:     [],
    students:   []
  ) }
  before(:each) do
    assign(:activity, activity)
    render
  end

  subject { rendered }
  it      { should     have_selector("span.label.label-success") }
  it      { should_not have_selector("tr.users") }
  it      { should_not have_selector("tr.meeting") }
  it      { should_not have_selector("tr.start-date") }
  it      { should_not have_selector("tr.end-date") }
  it      { should_not have_selector("tr.groups") }
  it      { should_not have_selector("tr.students") }
  it      { should_not have_selector("tr.notes") }

  context "with data" do
    let(:activity) { create(:activity,
      status:     :closed,
      start_date: Date.yesterday,
      end_date:   Date.tomorrow,
      meeting:    create(:meeting),
      users:      [create(:user)],
      groups:     [create(:group)],
      students:   [create(:student)]
    ) }
    it { should_not have_selector("span.label.label-success") }
    it { should     have_selector("tr.users") }
    it { should     have_selector("tr.meeting") }
    it { should     have_selector("tr.start-date") }
    it { should     have_selector("tr.end-date") }
    it { should     have_selector("tr.groups") }
    it { should     have_selector("tr.students") }
    it { should     have_selector("tr.notes") }
  end

  context "rendered fragments" do
    subject { view }
    it      { should render_template("_navigation") }
  end
end
