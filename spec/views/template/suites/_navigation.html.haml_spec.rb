require "spec_helper"

describe "template/suites/_navigation" do
  before(:each) { render }
  subject       { rendered }
  it            { should have_selector("li", count: 2) }
end
