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

    describe ".import_groups" do
      let(:method) { :import_groups }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }
      let(:mappings)    { {
        "instances" => { instance_id => instance.id }
      } }

      let(:input)  {
        Yajl.dump(
          attributes_for(:group).
          except(:instance, :parent).
          merge(_instance_id: instance_id, _parent_id: nil).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:group).
          except(:instance, :parent).
          merge(_instance_id: instance_id, _parent_id: "export-123").merge(_id: "export-124")
        )
      }

      subject(:groups) { Group.all }
      it               { should have(2).items }

      it "should set the group hierarchy" do
        group1, group2 = groups

        child  = group1.parent ? group1 : group2
        parent = group1.parent ? group2 : group1

        parent.parent.should be_nil
        child.parent.should  == parent
      end

      context "mappings" do
        subject      { importer.mappings["groups"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(groups.collect(&:id)) }
      end
    end

    describe ".import_instructions" do
      let(:method) { :import_instructions }

      let(:input)  {
        Yajl.dump(
          attributes_for(:instruction).merge(_id: "export-123", for_page: "/foo/bar")
        ) +
        Yajl.dump(
          attributes_for(:instruction).merge(_id: "export-124", for_page: "/bar/baz")
        )
      }

      subject(:instructions) { Instruction.all }
      it                     { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["instructions"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(instructions.collect(&:id)) }
      end
    end

    describe ".import_suites" do
      let(:method) { :import_suites }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }
      let(:mappings)    { {
        "instances" => { instance_id => instance.id }
      } }

      let(:input)  {
        Yajl.dump(
          attributes_for(:suite).
          except(:instance, :template).
          merge(_instance_id: instance_id, _template_id: nil, is_template: true).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:suite).
          except(:instance, :template).
          merge(_instance_id: instance_id, _template_id: "export-123").merge(_id: "export-124")
        )
      }

      subject(:suites) { Suite.all }
      it               { should have(2).items }

      it "should set the suite hierarchy" do
        suite1, suite2 = suites

        child          = suite1.template ? suite1 : suite2
        template       = suite1.template ? suite2 : suite1

        template.template.should be_nil
        child.template.should  == template
      end

      context "mappings" do
        subject      { importer.mappings["suites"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(suites.collect(&:id)) }
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

    describe ".handle_group_object" do
      let(:model)       { :group }
      let(:exclude)     { [ :instance, :parent ] }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }

      let(:_students)   { [] }
      let(:_users )     { [] }
      let(:meta)        { { _id: "export-123", _instance_id: instance_id, _parent_id: nil, _students: _students, _users: _users } }
      let(:method)      { :handle_group_object }

      before(:each) do
        importer.mappings["instances"] = { instance_id => instance.id }
      end

      subject(:result) { importer.handle_group_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.except(:data).stringify_keys) }
      its(:instance)   { should == instance }

      context "with existing mapping" do
        before(:each) do
          group = create(:group)
          importer.mappings["groups"]["export-123"] = group.id
        end
        it "does not create a new object" do
          result.should be_nil
          Group.count(:all).should == 1
        end
      end
      context "with users" do
        let(:users)  { create_list(:user, 2) }
        let(:_users) { %w(export-12 export-13) }

        before(:each) do
          importer.mappings["users"] = {
            "export-12" => users.first,
            "export-13" => users.second
          }
        end

        its(:users)  { should match_array(users)}
      end
      context "with students" do
        let(:students)  { create_list(:student, 2) }
        let(:_students) { %w(export-12 export-13) }

        before(:each) do
          importer.mappings["students"] = {
            "export-12" => students.first,
            "export-13" => students.second
          }
        end

        its(:students)  { should match_array(students)}
      end
    end

    describe ".handle_group_object_for_hierarchy" do
      let(:group)      { create(:group) }
      let(:parent)     { create(:group) }
      let(:_id)        { "export-13" }
      let(:_parent_id) { "export-12" }
      let(:object)     { { _id: _id, _parent_id: _parent_id } }

      before(:each) do
        importer.mappings["groups"] = {
          "export-12" => parent,
          "export-13" => group
        }
      end

      subject      { importer.handle_group_object_for_hierarchy(object) }

      it           { should == group }
      its(:parent) { should == parent }

      context "with no parent id" do
        let(:_parent_id) { nil }
        it               { should be_nil }
      end
      context "with existing parent" do
        let(:group)  { create(:group, parent: create(:group)) }
        it           { should == group }
        its(:parent) { should_not == parent}
      end
    end

    describe ".handle_instruction_object" do
      let(:model)       { :instruction }

      let(:meta)        { { _id: "export-123" } }
      let(:method)      { :handle_instruction_object }

      subject(:result) { importer.handle_instruction_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }

      context "with existing mapping" do
        before(:each) do
          instruction = create(:instruction)
          importer.mappings["instructions"]["export-123"] = instruction.id
        end
        it "does not create a new object" do
          result.should be_nil
          Instruction.count(:all).should == 1
        end
      end
      context "with existing instruction for a page" do
        let!(:instruction) { create(:instruction, for_page: object[:for_page]) }
        it "does not create a new object" do
          result.should                  == instruction
          Instruction.count(:all).should == 1
        end
      end
    end

    describe ".handle_suite_object" do
      let(:model)       { :suite }
      let(:exclude)     { [ :instance, :template ] }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }

      let(:meta)        {
        {
          _id: "export-123",
          _instance_id: instance_id,
          _template_id: 0,
          generic_evaluations: %w(export-10 export-11)
        }
      }

      let(:method)      { :handle_suite_object }

      before(:each) do
        importer.mappings["instances"] = { instance_id => instance.id }
      end

      subject(:result)          { importer.handle_suite_object(object) }

      it                        { should_not be_new_record }
      its(:attributes)          { should include(attributes.except(:generic_evaluations).stringify_keys) }
      its(:instance)            { should == instance }

      its(:generic_evaluations) { should match_array(%w(export-10 export-11)) }

      context "with existing mapping" do
        before(:each) do
          suite = create(:suite)
          importer.mappings["suites"]["export-123"] = suite.id
        end
        it "does not create a new object" do
          result.should be_nil
          Suite.count(:all).should == 1
        end
      end
    end

    describe ".handle_suite_object_for_hierarchy" do
      let(:suite)        { create(:suite) }
      let(:template)     { create(:suite, is_template: true) }
      let(:_id)          { "export-13" }
      let(:_template_id) { "export-12" }
      let(:object)       { { _id: _id, _template_id: _template_id } }

      before(:each) do
        importer.mappings["suites"] = {
          "export-12" => template,
          "export-13" => suite
        }
      end

      subject        { importer.handle_suite_object_for_hierarchy(object) }

      it             { should == suite }
      its(:template) { should == template }

      context "with no template id" do
        let(:_template_id) { nil }
        it               { should be_nil }
      end
      context "with existing template" do
        let(:suite)    { create(:suite, template: create(:suite, is_template: true)) }
        it             { should == suite }
        its(:template) { should_not == template}
      end
    end
  end
end
