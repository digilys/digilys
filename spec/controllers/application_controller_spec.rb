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
end
