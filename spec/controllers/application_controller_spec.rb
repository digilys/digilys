require 'spec_helper'

# https://www.relishapp.com/rspec/rspec-rails/v/2-4/docs/controller-specs/anonymous-controller
describe ApplicationController do
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

  describe "#results_to_datatable" do
    let!(:students)     { create_list(:student, 2) }
    let!(:evaluations)  { create_list(:evaluation, 2, max_result: 10, red_below: 4, green_above: 7) }
    let!(:result_s1_e1) { create(:result, evaluation: evaluations.first,  student: students.first,  value: 4) }
    let!(:result_s1_e2) { create(:result, evaluation: evaluations.second, student: students.first,  value: 5) }
    let!(:result_s2_e1) { create(:result, evaluation: evaluations.first,  student: students.second, value: 6) }
    let!(:result_s2_e2) { create(:result, evaluation: evaluations.second, student: students.second, value: 7) }

    subject(:table) { controller.send(:results_to_datatable, evaluations) }

    it { should have(3).items }

    context "title row" do
      subject { table.first }
      it { should have(3).items }
      its(:first)  { should == Evaluation.model_name.human(count: 2) }
      its(:second) { should == students.first.name }
      its(:third)  { should == students.second.name }
    end

    context "row for evaluation 1" do
      subject { table.second }
      it { should have(3).items }
      its(:first)  { should == evaluations.first.name }
      its(:second) { should == result_s1_e1.value }
      its(:third)  { should == result_s2_e1.value }
    end

    context "row for evaluation 2" do
      subject { table.third }
      it { should have(3).items }
      its(:first)  { should == evaluations.second.name }
      its(:second) { should == result_s1_e2.value }
      its(:third)  { should == result_s2_e2.value }
    end
  end
end
