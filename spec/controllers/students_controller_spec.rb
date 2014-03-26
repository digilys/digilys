require 'spec_helper'

describe StudentsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance)      { create(:instance) }
  let(:student)       { create(:student) }
  let(:other_student) { create(:student, instance: instance) }

  describe "GET #index" do
    let!(:students)             { create_list(:student, 2) }
    let!(:non_instance_student) { create(:student, instance: instance) }

    it "lists students in the current instance" do
      get :index
      expect(response).to be_successful
      expect(assigns(:students)).to match_array(students)
    end
    it "is filterable" do
      get :index, q: { last_name_cont: students.first.last_name }
      expect(response).to be_successful
      expect(assigns(:students)).to eq [students.first]
    end
  end

  describe "GET #search" do
    let!(:non_instance_student) { create(:student, first_name: student.first_name, last_name: student.last_name, instance: instance) }

    it "returns the result as json" do
      get :search, q: { name_cont: student.name }

      expect(response).to be_success
      json = JSON.parse(response.body)

      expect(json["more"]).to be_false

      expect(json["results"]).to have(1).items
      expect(json["results"].first).to include("id"   => student.id)
      expect(json["results"].first).to include("text" => student.name)
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: student.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :show, id: other_student.id
      expect(response.status).to be 404
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new
      expect(response).to be_success
    end
  end
  describe "POST #create" do
    it "redirects to the student when successful" do
      post :create, student: valid_parameters_for(:student)
      expect(response).to redirect_to(assigns(:student))
    end
    it "renders the new view when validation fails" do
      post :create, student: invalid_parameters_for(:student)
      expect(response).to render_template("new")
    end
    it "sets the instance from the current user's active instance" do
      post :create, student: valid_parameters_for(:student).merge(instance_id: instance.id)

      expect(assigns(:student).instance).not_to eq instance
      expect(assigns(:student).instance).to     eq logged_in_user.active_instance
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: student.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :show, id: other_student.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #update" do
    it "redirects to the student when successful" do
      new_name = "#{student.first_name} updated" 
      put :update, id: student.id, student: { first_name: new_name }
      expect(response).to redirect_to(student)
      expect(student.reload.first_name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: student.id, student: invalid_parameters_for(:student)
      expect(response).to render_template("edit")
    end
    it "gives a 404 if the instance does not match" do
      put :update, id: other_student.id, student: {}
      expect(response.status).to be 404
    end
    it "prevents changing the instance" do
      put :update, id: student.id, student: { instance_id: instance.id }
      expect(student.reload.instance).not_to eq instance
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: student.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_destroy, id: other_student.id
      expect(response.status).to be 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the student list page" do
      delete :destroy, id: student.id
      expect(response).to redirect_to(students_url())
      expect(Student.exists?(student.id)).to be_false
    end
    it "gives a 404 if the instance does not match" do
      delete :destroy, id: other_student.id
      expect(response.status).to be 404
    end
  end

  describe "GET #select_groups" do
    it "is successful" do
      get :select_groups, id: student.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :select_groups, id: other_student.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #add_groups" do
    let(:groups) { create_list(:group, 2) }

    it "adds groups and redirects back to the student" do
      expect(student.groups(true)).to be_blank
      put :add_groups, id: student.id, student: { groups: groups.collect(&:id).join(",") }
      expect(response).to redirect_to(student)
      expect(student.groups(true)).to match_array(groups)
    end
    it "gives a 404 if the instance does not match" do
      put :add_groups, id: other_student.id, student: { groups: groups.collect(&:id).join(",") }
      expect(response.status).to be 404
    end
  end
  describe "DELETE #remove_groups" do
    let(:groups) { create_list(:group, 2) }

    it "removes groups and redirects back to the student" do
      student.groups = groups
      delete :remove_groups, id: student.id, group_ids: groups.collect(&:id)
      expect(response).to redirect_to(student)
      expect(student.groups(true)).to be_blank
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_groups, id: other_student.id, group_ids: groups.collect(&:id)
      expect(response.status).to be 404
    end
  end
end
