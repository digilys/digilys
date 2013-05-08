require 'spec_helper'

describe ParticipantsController do
  describe "POST #create" do
    let(:suite)    { create(:suite) }
    let(:students) { create_list(:student, 3) }
    let(:groups)   { create_list(:group, 2) }

    let(:student_ids) { students.collect(&:id).join(",") }
    let(:group_ids)   { groups.collect(&:id).join(",") }

    before(:each) do
      groups.first.students  << students.first
      groups.second.students << students.second
    end

    it "creates multiple participants from multiple users" do
      post :create,
        participant: {
          suite_id:   suite.id,
          student_id: student_ids,
          group_id:   ""
        }
      suite.participants(true).map(&:student).should match_array(students)
    end
    it "creates multiple participants from one or more groups" do
      post :create,
        participant: {
          suite_id:   suite.id,
          student_id: "",
          group_id:   group_ids
        }
      suite.participants(true).map(&:student).should match_array([students.first, students.second])
    end
    it "assigns the group id to participants assigned from groups" do
      post :create,
        participant: {
          suite_id:   suite.id,
          student_id: "",
          group_id:   groups.first.id.to_s
        }

      suite.participants.first.group.should == groups.first
    end
    it "does not create duplicate participants" do
      post :create,
        participant: {
          suite_id:   suite.id,
          student_id: "#{student_ids},#{student_ids}",
          group_id:   group_ids
        }
      suite.participants(true).map(&:student).should match_array(students)
    end
  end
end
