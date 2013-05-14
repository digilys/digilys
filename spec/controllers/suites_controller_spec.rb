require 'spec_helper'

describe SuitesController do
  describe "POST #create" do
    let(:students) { create_list(:student, 3) }
    let(:groups)   { create_list(:group, 2) }

    let(:student_ids) { students.collect(&:id).join(",") }
    let(:group_ids)   { groups.collect(&:id).join(",") }

    before(:each) do
      groups.first.students  << students.first
      groups.second.students << students.second
    end

    it "creates participants from autocomplete data" do
      post :create,
        suite: {
          name: "Test suite",
          is_template: "0",
          participants_attributes: {
            "0" => {
              :student_id => student_ids,
              :group_id => group_ids
            }
          }
        }

      response.should redirect_to Suite.last
      Suite.last.participants.collect(&:student).should match_array(students)
    end
    it "does not create participants when the suite is a template" do
      post :create,
        suite: {
          name: "Test suite",
          is_template: "1",
          participants_attributes: {
            "0" => {
              :student_id => student_ids,
              :group_id => group_ids
            }
          }
        }

      response.should redirect_to Suite.last
      Suite.last.participants.should be_empty
    end
  end
end
