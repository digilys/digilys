require "spec_helper"

describe "activities/_list" do
  before(:each) do
    local(:activities, [
      create(:activity, start_date: nil,           end_date: nil),
      create(:activity, start_date: nil,           end_date: Date.yesterday), 
      create(:activity, start_date: Date.tomorrow, end_date: Date.tomorrow + 2.days)
    ])

    render
  end

  subject { rendered }
  it      { should have_selector("li",                      count: 3) }
  it      { should have_selector("li.overdue",              count: 1) }
  it      { should have_selector("small.date",              count: 2) }
  it      { should have_selector("small.date", text: / - /, count: 1) }
end
