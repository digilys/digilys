require 'spec_helper'

# https://www.relishapp.com/rspec/rspec-rails/v/2-4/docs/controller-specs/anonymous-controller
describe ApplicationController do
  describe "#current_instance" do
    let!(:instances)      { create_list(:instance, 3) }
    let(:active_instance) { instances.second }
    let(:user)            { create(:user, active_instance: active_instance) }
    before(:each)         { controller.stub(:current_user).and_return(user) }
    subject               { controller.send(:current_instance) }
    it                    { should == instances.second }
  end

  describe "#current_name_order" do
    let(:name_ordering) { nil }
    let(:user)          { build(:user, name_ordering: name_ordering) }
    before(:each)       { controller.stub(:current_user).and_return(user) }
    subject             { controller.send(:current_name_order) }
    it                  { should == "first_name, last_name" }

    context "by last_name" do
      let(:name_ordering) { :last_name }
      it                  { should == "last_name, first_name" }
    end

    context "with prefix" do
      let(:name_ordering) { :last_name }
      subject             { controller.send(:current_name_order, :students) }
      it                  { should == "students.last_name, students.first_name" }
    end
  end

  describe "#has_search_param?" do
    let(:allow_blank) { false }
    let(:params)      { {} }
    before(:each)     { controller.stub(:params).and_return(params) }
    subject           { controller.send(:has_search_param?, allow_blank) }

    it { should be_false }

    context "with search parameters" do
      let(:params) { { q: { foo: "bar" } } }
      it           { should be_true }
    end

    context "with blank search parameters" do
      let(:params) { { q: { foo: "", bar: nil } } }
      it           { should be_false }

      context "allowing blanks" do
        let(:allow_blank) { true }
        it                { should be_true }
      end
    end
  end

  describe "#process_participant_autocomplete_params" do
    let(:students) { create_list(:student, 3) }
    let(:groups)   { create_list(:group, 2) }

    before(:each) do
      groups.first.students  << students.first
      groups.second.students << students.second
    end

    let(:params)     { nil }
    subject(:result) { controller.send(:process_participant_autocomplete_params, params) }

    it { should be_nil }

    context "with comma separated student ids" do
      let(:params) { { student_id: "2,3" } }
      it { should match_array([ { student_id: 2 }, { student_id: 3 } ]) }
    end
    context "with a single student id" do
      let(:params) { { student_id: "2" } }
      it { should match_array([ { student_id: 2 } ]) }
    end

    context "with comma separated group ids" do
      let(:params) { { group_id: "#{groups.first.id},#{groups.second.id}" } }
      it {
        should match_array([
          { group_id: groups.first.id,  student_id: students.first.id },
          { group_id: groups.second.id, student_id: students.second.id }
        ])
      }
    end
    context "with a single group id" do
      let(:params) { { group_id: "#{groups.first.id}" } }
      it {
        should match_array([
          { group_id: groups.first.id, student_id: students.first.id }
        ])
      }
    end

    context "with the same student id explicit and from groups" do
      let(:params) { { group_id: "#{groups.first.id}", student_id: "#{students.first.id}" } }
      it {
        should match_array([
          { group_id: groups.first.id,  student_id: students.first.id }
        ])
      }
    end

    context "with duplicates" do
      let(:params) { { group_id: "#{groups.first.id},#{groups.first.id}", student_id: "#{students.first.id},#{students.first.id}" } }
      it {
        should match_array([
          { group_id: groups.first.id, student_id: students.first.id }
        ])
      }
    end
  end
end
