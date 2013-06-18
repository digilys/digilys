require 'spec_helper'

describe ParticipantsController do
  login_admin

  let(:participant) { create(:participant) }

  describe "GET #new" do
    it "assigns the participant's suite" do
      get "new", suite_id: participant.suite_id
      response.should be_success
      assigns(:participant).suite.should == participant.suite
    end
  end
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
      response.should redirect_to(suite)
      suite.participants(true).map(&:student).should match_array(students)
    end
    it "creates multiple participants from one or more groups" do
      post :create,
        participant: {
          suite_id:   suite.id,
          student_id: "",
          group_id:   group_ids
        }
      response.should redirect_to(suite)
      suite.participants(true).map(&:student).should match_array([students.first, students.second])
    end
    it "assigns the group id to participants assigned from groups" do
      post :create,
        participant: {
          suite_id:   suite.id,
          student_id: "",
          group_id:   groups.first.id.to_s
        }
      response.should redirect_to(suite)
      suite.participants.first.group.should == groups.first
    end
    it "does not create duplicate participants" do
      post :create,
        participant: {
          suite_id:   suite.id,
          student_id: "#{student_ids},#{student_ids}",
          group_id:   group_ids
        }
      response.should redirect_to(suite)
      suite.participants(true).map(&:student).should match_array(students)
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: participant.id
      response.should be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the participant list page" do
      delete :destroy, id: participant.id
      response.should redirect_to(participant.suite)
      Participant.exists?(participant.id).should be_false
    end
  end
end
