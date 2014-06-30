require "spec_helper"

describe "groups/index" do
  let(:parent)                    { create(:group) }
  let!(:child)                    { create(:group, parent: parent) }
  let!(:closed_child)             { create(:group, status: :closed) }
  let!(:closed_child_with_parent) { create(:group, parent: parent, status: :closed) }
  let(:has_search_param) { false }

  before(:each) do
    view.stub(:has_search_param?).and_return(has_search_param)
    view.stub(:params).and_return({:action => :index})

    assign(:groups, Kaminari.paginate_array([parent]).page(1).per(10))
    render
  end

  subject { rendered }

  it { should have_selector(".groups-table tbody tr", count: 2) }

  context "with search params does not render a tree" do
    let(:has_search_param) { true }
    it { should have_selector(".groups-table tbody tr", count: 1) }
  end

  context "closed groups" do
    it { should_not have_content(closed_child.name) }
    it { should_not have_content(closed_child_with_parent.name) }
  end

end
