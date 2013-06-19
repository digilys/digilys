require "spec_helper"

describe "shared/_confirm_destroy_form" do
  before(:each) do
    local(
      entity:      create(:user),
      message:     "Message",
      cancel_path: "/foo/bar"
    )
  end
  it "renders without errors" do
    render
  end
end
