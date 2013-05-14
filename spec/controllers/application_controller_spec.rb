require 'spec_helper'

# https://www.relishapp.com/rspec/rspec-rails/v/2-4/docs/controller-specs/anonymous-controller
describe ApplicationController do
  describe "#process_participant_autocomplete_params" do
    controller do
      def index
        @result = process_participant_autocomplete_params(params[:testdata])
        render nothing: true
      end
    end

    let(:students) { create_list(:student, 3) }
    let(:groups)   { create_list(:group, 2) }

    before(:each) do
      groups.first.students  << students.first
      groups.second.students << students.second
    end

    it "returns nil when there are no params" do
      get :index, testdata: nil
      assigns(:result).should be_nil
    end

    it "converts comma separated student ids" do
      get :index, testdata: { student_id: "2,3" }
      assigns(:result).should match_array([ { "student_id" => 2 }, { "student_id" => 3 } ])
    end
    it "handles a single student id" do
      get :index, testdata: { student_id: "2" }
      assigns(:result).should match_array([ { "student_id" => 2 } ])
    end

    it "converts comma separated group ids" do
      get :index, testdata: { group_id: "#{groups.first.id},#{groups.second.id}" }
      assigns(:result).should match_array([
        { "group_id" => groups.first.id,  "student_id" => students.first.id },
        { "group_id" => groups.second.id, "student_id" => students.second.id }
      ])
    end
    it "handles a single group id" do
      get :index, testdata: { group_id: "#{groups.first.id}" }
      assigns(:result).should match_array([
        { "group_id" => groups.first.id, "student_id" => students.first.id }
      ])
    end

    it "overrides an explicit student id if that student is also included from the group ids" do
      get :index, testdata: { group_id: "#{groups.first.id}", student_id: "#{students.first.id}" }
      assigns(:result).should match_array([
        { "group_id" => groups.first.id,  "student_id" => students.first.id }
      ])
    end

    it "ignores duplicates" do
      get :index, testdata: { group_id: "#{groups.first.id},#{groups.first.id}", student_id: "#{students.first.id},#{students.first.id}" }
      assigns(:result).should match_array([
        { "group_id" => groups.first.id, "student_id" => students.first.id }
      ])
    end
  end
end
