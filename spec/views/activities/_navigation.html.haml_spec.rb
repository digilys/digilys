require "spec_helper"

describe "activities/_navigation" do
  login_user(:admin)

  let(:activity) { create(:activity, status: :closed) }

  before(:each) do
    local(activity: activity)
    render
  end

  subject { rendered }
  it      { should have_selector("li:not(.secondaries)", count: 4) }

  context "with open activity" do
    let(:activity) { create(:activity, status: :open) }
    it             { should have_selector("li:not(.secondaries)", count: 5) }
  end
  context "with changed status" do
    let(:activity) do
      a = create(:activity, status: :open)
      a.status = :closed
      a
    end
    it { should have_selector("li:not(.secondaries)", count: 5) }
  end
end
