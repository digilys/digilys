require 'spec_helper'
require 'digilys/importer'

describe Digilys::Importer do

  let(:importer) { Digilys::Importer.new("export") }

  describe ".mappings=" do
    it "sets the default value of an assigned map to a new hash" do
      importer.mappings = {}
      importer.mappings[:foo].should == {}
    end
  end

  context "importers" do
    let(:input_io) { StringIO.new(input) }
    let(:mappings) { {} }

    before(:each) do
      mappings.each { |k,v| importer.mappings[k] = v }
      importer.send(method, input_io)
    end

    describe ".import_instances" do
      let(:method) { :import_instances }
      let(:input) {
        Yajl.dump(attributes_for(:instance).merge(_id: "export-123")) +
          Yajl.dump(attributes_for(:instance).merge(_id: "export-124"))
      }

      subject(:instances) { Instance.all }
      it                  { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["instances"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(instances.collect(&:id)) }
      end
    end

    describe ".import_users" do
      let(:method) { :import_users }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }
      let(:mappings)    { {
        "instances" => { instance_id => instance.id }
      } }

      let(:input)  {
        Yajl.dump(
          attributes_for(:user).
          except(:password, :password_confirmation).
          merge(_active_instance_id: instance_id, _roles: []).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:user).
          except(:password, :password_confirmation).
          merge(_active_instance_id: instance_id, _roles: []).merge(_id: "export-124")
        )
      }

      subject(:users) { User.all }
      it              { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["users"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(users.collect(&:id)) }
      end
    end

    describe ".import_students" do
      let(:method) { :import_students }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }
      let(:mappings)    { {
        "instances" => { instance_id => instance.id }
      } }

      let(:input)  {
        Yajl.dump(
          attributes_for(:student).
          except(:instance).
          merge(_instance_id: instance_id).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:student).
          except(:instance).
          merge(_instance_id: instance_id).merge(_id: "export-124")
        )
      }

      subject(:students) { Student.all }
      it                 { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["students"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(students.collect(&:id)) }
      end
    end
  end

  context "handlers" do
    let(:exclude) { [] }
    let(:attributes) {
      attributes_for(model).merge(
        created_at: Time.zone.now - 2.hours,
        updated_at: Time.zone.now - 1.hour
      ).except(*exclude)
    }
    let(:object) {
      attributes.merge(meta)
    }

    describe ".handle_instance_object" do
      let(:model)      { :instance }
      let(:meta)       { { _id: "export-123" } }
      let(:method)     { :handle_instance_object }

      subject(:result) { importer.handle_instance_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }

      context "with existing mapping" do
        before(:each) do
          instance = create(:instance)
          importer.mappings["instances"]["export-123"] = instance.id
        end
        it "does not create a new object" do
          result.should be_nil
          Instance.count(:all).should == 1
        end
      end
    end

    describe ".handle_user_object" do
      let(:model)       { :user }
      let(:exclude)     { [ :password, :password_confirmation ] }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }

      let(:meta)        { { _id: "export-123", _active_instance_id: instance_id } }
      let(:method)      { :handle_user_object }

      before(:each) do
        importer.mappings["instances"] = { instance_id => instance.id }
      end

      subject(:result)      { importer.handle_user_object(object) }

      it                    { should_not be_new_record }
      its(:attributes)      { should include(attributes.stringify_keys) }
      its(:active_instance) { should == instance }

      context "with existing mapping" do
        before(:each) do
          user = create(:user)
          importer.mappings["users"]["export-123"] = user.id
        end
        it "does not create a new object" do
          result.should be_nil
          User.count(:all).should == 1
        end
      end
      context "with existing user email" do
        let!(:user) { create(:user, email: object[:email]) }
        it          { should == user }

        context "in mapping" do
          subject { result; importer.mappings["users"] }
          it      { should include("export-123" => user.id) }
        end
      end
    end

    describe ".handle_student_object" do
      let(:model)       { :student }
      let(:exclude)     { [ :instance ] }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }

      let(:meta)        { { _id: "export-123", _instance_id: instance_id } }
      let(:method)      { :handle_student_object }

      before(:each) do
        importer.mappings["instances"] = { instance_id => instance.id }
      end

      subject(:result) { importer.handle_student_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.except(:data).stringify_keys) }
      its(:attributes) { should include("data" => {}) }
      its(:instance)   { should == instance }

      context "with existing mapping" do
        before(:each) do
          student = create(:student)
          importer.mappings["students"]["export-123"] = student.id
        end
        it "does not create a new object" do
          result.should be_nil
          Student.count(:all).should == 1
        end
      end
      context "with existing student personal id" do
        let!(:student) { create(:student, personal_id: object[:personal_id]) }
        it             { should == student }

        context "in mapping" do
          subject { result; importer.mappings["students"] }
          it      { should include("export-123" => student.id) }
        end
      end
    end
  end
end
