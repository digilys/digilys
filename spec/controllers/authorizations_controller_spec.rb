require 'spec_helper'

describe AuthorizationsController do
  login_user(:admin)

  let(:user)        { create(:user) }
  let(:color_table) { create(:color_table) }

  describe "POST #create" do
    it "adds privileges for the subject to the user" do
      post :create, color_table_id: color_table.id, user_id: user.id, roles: :reader
      response.should              be_successful
      response.should              render_template("authorizations/create")
      response.content_type.should == "application/json"
      user.should                  have_role(:reader, color_table)
    end
    it "supports multiple roles separated by commas" do
      post :create, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager"
      response.should be_successful
      user.should have_role(:reader,  color_table)
      user.should have_role(:editor,  color_table)
      user.should have_role(:manager, color_table)
    end
    it "only allows reader, editor and manager as roles" do
      post :create, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager,foo"
      response.should be_successful
      user.should     have_role(:reader,  color_table)
      user.should     have_role(:editor,  color_table)
      user.should     have_role(:manager, color_table)
      user.should_not have_role(:foo,     color_table)
    end

    context "without privileges" do
      login_user

      it "disallows creating an authorization" do
        post :create, color_table_id: color_table.id, user_id: user.id
        response.status.should == 401
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
      response.should              be_successful
      response.content_type.should == "application/json"
      user.should_not              have_role(:reader, color_table)
    end
    it "returns the user's details in a json response" do
      delete :destroy, color_table_id: color_table.id, user_id: user.id
      json = JSON.parse(response.body)
      json["id"].should    == user.id
      json["name"].should  == user.name
      json["email"].should == user.email
    end
    it "supports multiple roles separated by commas" do
      delete :destroy, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager"
      response.should be_successful
      user.should_not have_role(:reader,  color_table)
      user.should_not have_role(:editor,  color_table)
      user.should_not have_role(:manager, color_table)
    end
    it "does not touch other roles" do
      user.add_role :instance, color_table
      user.add_role :resource, ColorTable
      user.add_role :global

      delete :destroy, color_table_id: color_table.id, user_id: user.id, roles: "reader,editor,manager,instance"
      response.should be_successful

      user.should_not have_role(:reader,   color_table)
      user.should_not have_role(:editor,   color_table)
      user.should_not have_role(:manager,  color_table)
      user.should     have_role(:instance, color_table)
      user.should     have_role(:resource, ColorTable)
      user.should     have_role(:global)
    end

    context "without privileges" do
      login_user

      it "disallows creating an authorization" do
        delete :destroy, color_table_id: color_table.id, user_id: user.id
        response.status.should == 401
      end
    end
  end
end
