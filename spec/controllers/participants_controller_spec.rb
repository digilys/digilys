require 'spec_helper'

describe ParticipantsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:participant)       { create(:participant) }
  let(:instance)          { create(:instance) }
  let(:other_suite)       { create(:suite, instance: instance) }
  let(:other_participant) { create(:participant, suite: other_suite, student: create(:student, instance: instance)) }

  describe "GET #new" do
    it "assigns the participant's suite" do
      get "new", suite_id: participant.suite_id
      expect(response).to be_success
      expect(assigns(:participant).suite).to eq participant.suite
    end
    it "gives a 404 if the suite instance does not match" do
      get "new", suite_id: other_suite.id
      expect(response.status).to be 404
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
      post(
        :create,
        participant: {
          suite_id:   suite.id,
          student_id: student_ids,
          group_id:   ""
        }
      )
      expect(response).to redirect_to(suite)
      expect(suite.participants(true).map(&:student)).to match_array(students)
    end
    it "creates multiple participants from one or more groups" do
      post(
        :create,
        participant: {
          suite_id:   suite.id,
          student_id: "",
          group_id:   group_ids
        }
      )
      expect(response).to redirect_to(suite)
      expect(suite.participants(true).map(&:student)).to match_array([students.first, students.second])
    end
    it "assigns the group id to participants assigned from groups" do
      post(
        :create,
        participant: {
          suite_id:   suite.id,
          student_id: "",
          group_id:   groups.first.id.to_s
        }
      )
      expect(response).to redirect_to(suite)
      expect(suite.participants.first.group).to eq groups.first
    end
    it "does not create duplicate participants" do
      post(
        :create,
        participant: {
          suite_id:   suite.id,
          student_id: "#{student_ids},#{student_ids}",
          group_id:   group_ids
        }
      )
      expect(response).to redirect_to(suite)
      expect(suite.participants(true).map(&:student)).to match_array(students)
    end
    it "gives a 404 if the suite instance does not match" do
      post(
        :create,
        participant: {
          suite_id:   other_suite.id,
          student_id: student_ids,
          group_id:   group_ids
        }
      )
      expect(response.status).to be 404
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: participant.id
      expect(response).to be_success
    end
    it "gives a 404 if the suite instance does not match" do
      get :confirm_destroy, id: other_participant.id
      expect(response.status).to be 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the participant list page" do
      delete :destroy, id: participant.id
      expect(response).to redirect_to(participant.suite)
      expect(Participant.exists?(participant.id)).to be_false
    end
    it "gives a 404 if the suite instance does not match" do
      delete :destroy, id: other_participant.id
      expect(response.status).to be 404
    end
  end
end
