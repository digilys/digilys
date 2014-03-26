require 'spec_helper'

describe AuthorizationsController do
  login_user(:admin)

  let(:user)        { create(:user) }
  let(:color_table) { create(:color_table) }

  describe "POST #create" do
    it "adds privileges for the subject to the user" do
      post :create, color_table_id: color_table.id, user_id: user.id, roles: :reader
      expect(response).to              be_successful
      expect(response).to              render_template("authorizations/create")
      expect(response.content_type).to eq "application/json"
      expect(user).to                  have_role(:reader, color_table)
    end
    it "supports multiple roles separated by commas" do
      post :create, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager"
      expect(response).to be_successful
      expect(user).to have_role(:reader,  color_table)
      expect(user).to have_role(:editor,  color_table)
      expect(user).to have_role(:manager, color_table)
    end
    it "only allows reader, editor and manager as roles" do
      post :create, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager,foo"
      expect(response).to be_successful
      expect(user).to     have_role(:reader,  color_table)
      expect(user).to     have_role(:editor,  color_table)
      expect(user).to     have_role(:manager, color_table)
      expect(user).not_to have_role(:foo,     color_table)
    end

    context "without privileges" do
      login_user

      it "disallows creating an authorization" do
        post :create, color_table_id: color_table.id, user_id: user.id
        expect(response.status).to be 401
      end
    end
  end

  describe "DELETE #destroy" do
    before(:each) do
      user.add_role :reader,  color_table
      user.add_role :editor,  color_table
      user.add_role :manager, color_table
    end
    it "removes privileges for the subject to the user" do
      delete :destroy, color_table_id: color_table.id, user_id: user.id, roles: :reader
      expect(response).to              be_successful
      expect(response.content_type).to eq "application/json"
      expect(user).not_to              have_role(:reader, color_table)
    end
    it "returns the user's details in a json response" do
      delete :destroy, color_table_id: color_table.id, user_id: user.id
      json = JSON.parse(response.body)
      expect(json["id"]).to    eq user.id
      expect(json["name"]).to  eq user.name
      expect(json["email"]).to eq user.email
    end
    it "supports multiple roles separated by commas" do
      delete :destroy, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager"
      expect(response).to be_successful
      expect(user).not_to have_role(:reader,  color_table)
      expect(user).not_to have_role(:editor,  color_table)
      expect(user).not_to have_role(:manager, color_table)
    end
    it "does not touch other roles" do
      user.add_role :instance, color_table
      user.add_role :resource, ColorTable
      user.add_role :global

      delete :destroy, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager,instance"
      expect(response).to be_successful

      expect(user).not_to have_role(:reader,   color_table)
      expect(user).not_to have_role(:editor,   color_table)
      expect(user).not_to have_role(:manager,  color_table)
      expect(user).to     have_role(:instance, color_table)
      expect(user).to     have_role(:resource, ColorTable)
      expect(user).to     have_role(:global)
    end

    context "without privileges" do
      login_user

      it "disallows creating an authorization" do
        delete :destroy, color_table_id: color_table.id, user_id: user.id
        expect(response.status).to be 401
      end
    end
  end
end
