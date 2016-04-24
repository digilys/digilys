require 'spec_helper'

describe GroupsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance)    { create(:instance) }
  let(:group)       { create(:group) }
  let(:other_group) { create(:group, instance: instance) }

  describe "GET #index" do
    let!(:top_level) { create_list(:group, 2) }
    let!(:children)  { create_list(:group, 2, parent: top_level.first) }

    let!(:non_instance_group) { other_group }

    it "lists top level groups" do
      get :index
      expect(response).to be_successful
      expect(assigns(:groups)).to match_array(top_level)
    end
    it "filters all groups" do
      get :index, q: { name_cont: children.first.name }
      expect(response).to be_successful
      expect(assigns(:groups)).to eq [children.first]
    end
    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "is successful" do
        get :index
        expect(response).to be_successful
        expect(assigns(:groups)).to match_array(top_level)
      end
    end
  end

  describe "GET #closed" do
    let!(:closed_groups) { create_list(:group, 2, status: :closed) }
    let!(:open_groups) { create_list(:group, 1, status: :open) }


    it "lists closed groups" do
      get :closed
      expect(response).to be_successful
      expect(assigns(:groups)).to match_array(closed_groups)
    end
    it "filters all closed groups" do
      get :closed, q: { name_cont: closed_groups.first.name }
      expect(response).to be_successful
      expect(assigns(:groups)).to eq [closed_groups.first]
    end
    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "lists closed groups" do
        get :closed
        expect(response).to be_successful
        expect(assigns(:groups)).to match_array(closed_groups)
      end
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: group.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :show, id: other_group.id
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "is successful" do
        get :show, id: group.id
        expect(response).to be_success
      end
    end
  end

  describe "GET #search" do
    let(:grandparent)  { create(:group) }
    let(:parent)       { create(:group, parent: grandparent) }
    let(:group)        { create(:group, parent: parent) }
    let(:closed_group) { create(:group, status: :closed) }

    let!(:non_instance_group) { create(:group, name: group.name, instance: instance) }

    it "returns the result as json" do
      get :search, q: { name_cont: group.name }

      expect(response).to be_success
      json = JSON.parse(response.body)

      expect(json["more"]).to be_false

      expect(json["results"]).to have(1).items
      expect(json["results"].first).to include("id"   => group.id)
      expect(json["results"].first).to include("text" => "#{group.name}, #{parent.name}, #{grandparent.name}")
    end

    it "returns no closed groups" do
      get :search, q: { name_cont: closed_group.name }

      expect(response).to be_success
      json = JSON.parse(response.body)

      expect(json["results"]).to have(0).items
    end

    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns the result as json" do
        get :search, q: { name_cont: group.name }

        expect(response).to be_success
        json = JSON.parse(response.body)

        expect(json["more"]).to be_false

        expect(json["results"]).to have(1).items
      end
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new
      expect(response).to be_success
    end
    it "loads the group to copy from if specified" do
      copy_from = create(:group)
      get :new, copy_from: copy_from.id
      expect(assigns(:copy_from)).to eq(copy_from)
    end
    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "is successful" do
        get :new
        expect(response).to be_success
      end
      it "loads the group to copy from if specified" do
        copy_from = create(:group)
        get :new, copy_from: copy_from.id
        expect(assigns(:copy_from)).to eq(copy_from)
      end
    end
  end
  describe "POST #create" do
    it "redirects to the group when successful" do
      post :create, group: valid_parameters_for(:group)
      expect(response).to redirect_to(assigns(:group))
    end
    it "renders the new view when validation fails" do
      post :create, group: invalid_parameters_for(:group)
      expect(response).to render_template("new")
    end
    it "sets the instance from the current user's active instance" do
      post :create, group: valid_parameters_for(:group).merge(instance_id: instance.id)

      expect(assigns(:group).instance).not_to eq instance
      expect(assigns(:group).instance).to     eq logged_in_user.active_instance
    end

    context "with a group to copy from" do
      let(:copy_from) { create(:group) }
      let(:students) { create_list(:student, 2) }

      before(:each) do
        copy_from.add_students(students)
      end

      it "copies the students from the group" do
        post :create, group: valid_parameters_for(:group), copy_from: copy_from.id
        expect(response).to redirect_to(assigns(:group))
        expect(assigns(:group).students).to match_array(students)
      end
    end

    context "as instance admin" do
      login_user(:user)
      let(:copy_from) { create(:group) }
      let(:students) { create_list(:student, 2) }

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
        copy_from.add_students(students)
      end

      it "redirects to the group when successful" do
        post :create, group: valid_parameters_for(:group)
        expect(response).to redirect_to(assigns(:group))
      end

      it "copies the students from the group" do
        post :create, group: valid_parameters_for(:group), copy_from: copy_from.id
        expect(response).to redirect_to(assigns(:group))
        expect(assigns(:group).students).to match_array(students)
      end
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: group.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :edit, id: other_group.id
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        get :edit, id: group.id
        expect(response.status).to be 401
      end
    end
  end

  describe "PUT #update" do
    it "redirects to the group when successful" do
      new_name = "#{group.name} updated"
      put :update, id: group.id, group: { name: new_name }
      expect(response).to redirect_to(group)
      expect(group.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: group.id, group: invalid_parameters_for(:group)
      expect(response).to render_template("edit")
    end
    it "gives a 404 if the instance does not match" do
      put :update, id: other_group.id, group: {}
      expect(response.status).to be 404
    end
    it "prevents changing the instance" do
      put :update, id: group.id, group: { instance_id: instance.id }
      expect(group.reload.instance).not_to eq instance
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        new_name = "#{group.name} updated"
        put :update, id: group.id, group: { name: new_name }
        expect(response.status).to be 401
      end
    end
  end

  describe "GET #confirm_status_change" do
    it "switches the status without saving" do
      get :confirm_status_change, id: group.id
      expect(response).to be_success
      expect(assigns(:group).status.to_sym).to be :closed
      expect(assigns(:group)).to be_changed
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_status_change, id: other_group.id
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "switches the status without saving" do
        get :confirm_status_change, id: group.id
        expect(response).to be_success
        expect(assigns(:group).status.to_sym).to be :closed
        expect(assigns(:group)).to be_changed
      end
    end
  end

  describe "PUT #change_status" do
    it "updates the status and redirects to the group page" do
      put :change_status, id: group.id, group: { status: "closed" }
      expect(response).to redirect_to(group)
      expect(group.reload).to be_closed
    end
    it "renders the confirm_change_status view when validation fails" do
      put :change_status, id: group.id, group: { status: "invalid" }
      expect(response).to render_template("confirm_status_change")
    end
    it "gives a 404 if the instance does not match" do
      put :change_status, id: other_group.id
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "updates the status and redirects to the group page" do
        put :change_status, id: group.id, group: { status: "closed" }
        expect(response).to redirect_to(group)
        expect(group.reload).to be_closed
      end
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: group.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_destroy, id: other_group.id
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        get :confirm_destroy, id: group.id
        expect(response.status).to be 401
      end
    end
  end

  describe "DELETE #destroy" do
    it "redirects to the group list page" do
      delete :destroy, id: group.id
      expect(response).to redirect_to(groups_url())
      expect(Group.exists?(group.id)).to be_false
    end
    it "gives a 404 if the instance does not match" do
      delete :destroy, id: other_group.id
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        delete :destroy, id: group.id
        expect(response.status).to be 401
      end
    end
  end

  describe "GET #select_students" do
    it "is successful" do
      get :select_students, id: group.id
      expect(response).to be_success
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        get :select_students, id: group.id
        expect(response.status).to be 401
      end
    end
  end

  describe "PUT #add_students" do
    let(:students) { create_list(:student, 2) }

    it "adds students and redirects back to the group" do
      expect(group.students(true)).to be_blank
      put :add_students, id: group.id, group: { students: students.collect(&:id).join(",") }
      expect(response).to redirect_to(group)
      expect(group.students(true)).to match_array(students)
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        expect(group.students(true)).to be_blank
        put :add_students, id: group.id, group: { students: students.collect(&:id).join(",") }
        expect(response.status).to be 401
      end
    end
  end

  describe "GET #move_students" do
    it "is successful" do
      get :move_students, id: group.id
      expect(response).to be_success
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "is successful" do
        get :move_students, id: group.id
        expect(response).to be_success
      end
    end
  end

  describe "PUT #move_students" do
    let(:destination)    { create(:group) }
    let(:students)       { create_list(:student, 2) }
    let(:students_moved) { create_list(:student, 2) }

    before(:each) { group.students = students + students_moved }

    it "moves students from a group to another" do
      put :move_students, id: group.id, group: { group: destination.id }, student_ids: students_moved.collect(&:id)
      expect(response).to redirect_to(group)

      expect(group.students(true)).to       match_array(students)
      expect(destination.students(true)).to match_array(students_moved)
    end

    it "produces an error when no group has been selected" do
      put :move_students, id: group.id, group: { group: "" }, student_ids: students_moved.collect(&:id)
      expect(response).to redirect_to(action: "move_students")

      expect(group.students(true)).to match_array(students + students_moved)
    end

    it "gives a 404 if the instance does not match" do
      put :move_students, id: other_group.id, group: { group: destination.id }, student_ids: students_moved.collect(&:id)
      expect(response.status).to be 404
    end
    it "gives a 404 if the destination's instance does not match" do
      put :move_students, id: group.id, group: { group: other_group.id }, student_ids: students_moved.collect(&:id)
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "moves students from a group to another" do
        put :move_students, id: group.id, group: { group: destination.id }, student_ids: students_moved.collect(&:id)
        expect(response).to redirect_to(group)

        expect(group.students(true)).to       match_array(students)
        expect(destination.students(true)).to match_array(students_moved)
      end
    end
  end

  describe "DELETE #remove_students" do
    let(:students) { create_list(:student, 2) }

    it "removes students and redirects back to the group" do
      group.students = students
      delete :remove_students, id: group.id, student_ids: students.collect(&:id)
      expect(response).to redirect_to(group)
      expect(group.students(true)).to be_blank
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_students, id: other_group.id, student_ids: students.collect(&:id)
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        group.students = students
        delete :remove_students, id: group.id, student_ids: students.collect(&:id)
        expect(response.status).to be 401
      end
    end
  end

  describe "GET #select_users" do
    it "is successful" do
      get :select_users, id: group.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :select_users, id: other_group.id
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        get :select_users, id: group.id
        expect(response.status).to be 401
      end
    end
  end

  describe "PUT #add_users" do
    let(:users) { create_list(:user, 2) }

    it "adds users and redirects back to the group" do
      expect(group.users(true)).to be_blank
      put :add_users, id: group.id, group: { users: users.collect(&:id).join(",") }
      expect(response).to redirect_to(group)
      expect(group.users(true)).to match_array(users)
    end
    it "gives a 404 if the instance does not match" do
      put :add_users, id: other_group.id, group: { users: users.collect(&:id).join(",") }
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        expect(group.users(true)).to be_blank
        put :add_users, id: group.id, group: { users: users.collect(&:id).join(",") }
        expect(response.status).to be 401
      end
    end
  end

  describe "DELETE #remove_users" do
    let(:users) { create_list(:user, 2) }

    it "removes users and redirects back to the group" do
      group.users = users
      delete :remove_users, id: group.id, user_ids: users.collect(&:id)
      expect(response).to redirect_to(group)
      expect(group.users(true)).to be_blank
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_users, id: other_group.id, user_ids: users.collect(&:id)
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end

      it "returns 401" do
        group.users = users
        delete :remove_users, id: group.id, user_ids: users.collect(&:id)
        expect(response.status).to be 401
      end
    end
  end
end
