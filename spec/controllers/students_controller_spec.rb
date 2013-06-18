require 'spec_helper'

describe StudentsController do
  login_admin

  let(:student) { create(:student) }

  describe "GET #index" do
    let!(:students) { create_list(:student, 2) }

    it "lists top level students" do
      get :index
      response.should be_successful
      assigns(:students).should match_array(students)
    end
  end

  describe "GET #search" do
    it "returns the result as json" do
      get :search, q: { name_cont: student.name }

      response.should be_success
      json = JSON.parse(response.body)

      json["more"].should be_false

      json["results"].should have(1).items
      json["results"].first.should include("id"          => student.id)
      json["results"].first.should include("text"        => student.name)
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: student.id
      response.should be_success
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new
      response.should be_success
    end
  end
  describe "POST #create" do
    it "redirects to the student when successful" do
      post :create, student: valid_parameters_for(:student)
      response.should redirect_to(assigns(:student))
    end
    it "renders the new view when validation fails" do
      post :create, student: invalid_parameters_for(:student)
      response.should render_template("new")
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: student.id
      response.should be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the student when successful" do
      new_name = "#{student.first_name} updated" 
      put :update, id: student.id, student: { first_name: new_name }
      response.should redirect_to(student)
      student.reload.first_name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: student.id, student: invalid_parameters_for(:student)
      response.should render_template("edit")
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: student.id
      response.should be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the student list page" do
      delete :destroy, id: student.id
      response.should redirect_to(students_url())
      Student.exists?(student.id).should be_false
    end
  end

  describe "GET #select_groups" do
    it "is successful" do
      get :select_groups, id: student.id
      response.should be_success
    end
  end
  describe "PUT #add_groups" do
    let(:groups) { create_list(:group, 2) }

    it "adds groups and redirects back to the student" do
      student.groups(true).should be_blank
      put :add_groups, id: student.id, student: { groups: groups.collect(&:id).join(",") }
      response.should redirect_to(student)
      student.groups(true).should match_array(groups)
    end
  end
  describe "DELETE #remove_groups" do
    let(:groups) { create_list(:group, 2) }

    it "removes groups and redirects back to the student" do
      student.groups = groups
      delete :remove_groups, id: student.id, group_ids: groups.collect(&:id)
      response.should redirect_to(student)
      student.groups(true).should be_blank
    end
  end
end
