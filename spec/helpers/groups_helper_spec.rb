require 'spec_helper'

describe GroupsHelper do
  describe "#render_group_tree" do
    let!(:top1)    { create(:group, name: "top1") }
    let!(:top2)    { create(:group, name: "top2") }
    let!(:second1) { create(:group, name: "second1", parent: top1) }
    let!(:second2) { create(:group, name: "second2", parent: top1) }
    let!(:third1)  { create(:group, name: "third1", parent: second2) }
    let!(:third2)  { create(:group, name: "third2", parent: second2) }

    let(:result)   { helper.render_group_tree([top1, top2]) }

    subject(:html) { Capybara::Node::Simple.new(result) }

    context "with no groups" do
      let(:result) { helper.render_group_tree(nil) }
      it           { should_not have_selector("td.name") }
    end

    it { should have_selector("td.name", count: 6) }

    context "first row" do
      subject { html.find(:xpath, "//tr[1]/td[1]") }
      it      { should have_content(top1.name) }
    end
    context "second row" do
      subject { html.find(:xpath, "//tr[2]/td[1]") }
      it      { should have_content(second1.name) }
    end
    context "third row" do
      subject { html.find(:xpath, "//tr[3]/td[1]") }
      it      { should have_content(second2.name) }
    end
    context "fourth row" do
      subject { html.find(:xpath, "//tr[4]/td[1]") }
      it      { should have_content(third1.name) }
    end
    context "fifth row" do
      subject { html.find(:xpath, "//tr[5]/td[1]") }
      it      { should have_content(third2.name) }
    end
    context "sixth row" do
      subject { html.find(:xpath, "//tr[6]/td[1]") }
      it      { should have_content(top2.name) }
    end
  end
end
