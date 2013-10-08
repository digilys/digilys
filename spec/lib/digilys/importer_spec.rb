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
    let(:setup)    { nil }

    before(:each) do
      setup
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

    describe ".import_participants" do
      let(:method)      { :import_participants }

      let(:suite)       { create(:suite) }
      let(:suite_id)    { "export-1" }
      let(:student1)    { create(:student) }
      let(:student1_id) { "export-2" }
      let(:student2)    { create(:student) }
      let(:student2_id) { "export-3" }
      let(:group)       { create(:group) }
      let(:group_id)    { "export-4" }
      let(:mappings)    { {
        "suites"   => { suite_id    => suite.id },
        "students" => { student1_id => student1.id, student2_id => student2.id },
        "groups"   => { group_id    => group.id }
      } }

      let(:input)  {
        Yajl.dump(
          attributes_for(:participant).
          merge(_suite_id: suite_id, _student_id: student1_id).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:participant).
          merge(_suite_id: suite_id, _student_id: student2_id, _group_id: group_id).merge(_id: "export-124")
        )
      }

      subject(:participants) { Participant.all }
      it                     { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["participants"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(participants.collect(&:id)) }
      end
    end

    describe ".import_meetings" do
      let(:method)   { :import_meetings }

      let(:suite)    { create(:suite) }
      let(:suite_id) { "export-1" }
      let(:mappings) { {
        "suites"   => { suite_id    => suite.id },
      } }

      let(:input) {
        Yajl.dump(
          attributes_for(:meeting).
          merge(_suite_id: suite_id).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:meeting).
          merge(_suite_id: suite_id).merge(_id: "export-124")
        )
      }

      subject(:meetings) { Meeting.all }
      it                 { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["meetings"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(meetings.collect(&:id)) }
      end
    end

    describe ".import_activities" do
      let(:method)     { :import_activities }

      let(:suite)      { create(:suite) }
      let(:suite_id)   { "export-1" }
      let(:meeting)    { create(:meeting) }
      let(:meeting_id) { "export-2" }
      let(:mappings)   { {
        "suites"   => { suite_id   => suite.id },
        "meetings" => { meeting_id => meeting.id }
      } }

      let(:input) {
        Yajl.dump(
          attributes_for(:activity).
          except(:meeting).
          merge(_suite_id: suite_id, _meeting_id: meeting_id).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:activity).
          except(:meeting).
          merge(_suite_id: suite_id, _meeting_id: nil).merge(_id: "export-124")
        )
      }

      subject(:activities) { Activity.all }
      it                   { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["activities"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(activities.collect(&:id)) }
      end
    end

    describe ".import_generic_evaluations" do
      let(:method)      { :import_generic_evaluations }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }
      let(:mappings)    { {
        "instances" => { instance_id => instance.id }
      } }

      let(:exclude)     { [
        :instance,
        :template,
        :suite,
        :red_min,
        :red_max,
        :yellow_min,
        :yellow_max,
        :green_min,
        :green_max,
        :stanine1_min,
        :stanine1_max,
        :stanine2_min,
        :stanine2_max,
        :stanine3_min,
        :stanine3_max,
        :stanine4_min,
        :stanine4_max,
        :stanine5_min,
        :stanine5_max,
        :stanine6_min,
        :stanine6_max,
        :stanine7_min,
        :stanine7_max,
        :stanine8_min,
        :stanine8_max,
        :stanine9_min,
        :stanine9_max,
      ] }
      let(:input)  {
        Yajl.dump(
          attributes_for(:generic_evaluation).
          except(*exclude).
          merge(_instance_id: instance_id).merge(_id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:generic_evaluation).
          except(*exclude).
          merge(_instance_id: instance_id).merge(_id: "export-124")
        )
      }

      subject(:generic_evaluations) { Evaluation.all }
      it                            { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["generic_evaluations"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(generic_evaluations.collect(&:id)) }
      end
      context "suite references" do
        let(:suite) { create(:suite, generic_evaluations: %w(export-123 export-124) << 0) }
        let(:setup) { suite }
        subject     { suite.reload.generic_evaluations }
        it          { should match_array(Evaluation.all.collect(&:id) << 0) }
      end
    end

    describe ".import_evaluation_templates" do
      let(:method)      { :import_evaluation_templates }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }
      let(:mappings)    { {
        "instances" => { instance_id => instance.id }
      } }

      let(:exclude)     { [
        :instance,
        :template,
        :suite,
        :red_min,
        :red_max,
        :yellow_min,
        :yellow_max,
        :green_min,
        :green_max,
        :stanine1_min,
        :stanine1_max,
        :stanine2_min,
        :stanine2_max,
        :stanine3_min,
        :stanine3_max,
        :stanine4_min,
        :stanine4_max,
        :stanine5_min,
        :stanine5_max,
        :stanine6_min,
        :stanine6_max,
        :stanine7_min,
        :stanine7_max,
        :stanine8_min,
        :stanine8_max,
        :stanine9_min,
        :stanine9_max,
      ] }
      let(:input)  {
        Yajl.dump(
          attributes_for(:evaluation_template).
          except(*exclude).
          merge(_instance_id: instance_id, _template_id: nil, _id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:evaluation_template).
          except(*exclude).
          merge(_instance_id: instance_id, _template_id: "export-123", _id: "export-124")
        )
      }

      subject(:evaluation_templates) { Evaluation.all }
      it                             { should have(2).items }

      it "should set the template hierarchy" do
        evaluation1, evaluation2 = evaluation_templates

        child          = evaluation1.template ? evaluation1 : evaluation2
        template       = evaluation1.template ? evaluation2 : evaluation1

        template.template.should be_nil
        child.template.should  == template
      end

      context "mappings" do
        subject      { importer.mappings["evaluation_templates"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(evaluation_templates.collect(&:id)) }
      end
    end

    describe ".import_suite_evaluations" do
      let(:method)   { :import_suite_evaluations }

      let(:suite)    { create(:suite) }
      let(:suite_id) { "export-1" }
      let(:mappings) { {
        "suites" => { suite_id => suite.id }
      } }

      let(:exclude)     { [
        :instance,
        :template,
        :suite,
        :red_min,
        :red_max,
        :yellow_min,
        :yellow_max,
        :green_min,
        :green_max,
        :stanine1_min,
        :stanine1_max,
        :stanine2_min,
        :stanine2_max,
        :stanine3_min,
        :stanine3_max,
        :stanine4_min,
        :stanine4_max,
        :stanine5_min,
        :stanine5_max,
        :stanine6_min,
        :stanine6_max,
        :stanine7_min,
        :stanine7_max,
        :stanine8_min,
        :stanine8_max,
        :stanine9_min,
        :stanine9_max,
      ] }
      let(:input)  {
        Yajl.dump(
          attributes_for(:suite_evaluation).
          except(*exclude).
          merge(_suite_id: suite_id, _id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:suite_evaluation).
          except(*exclude).
          merge(_suite_id: suite_id, _id: "export-124")
        )
      }

      subject(:suite_evaluations) { Evaluation.all }
      it                          { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["suite_evaluations"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(suite_evaluations.collect(&:id)) }
      end
    end

    describe ".import_result" do
      let(:method)        { :import_results }

      let(:evaluation)    { create(:suite_evaluation) }
      let(:evaluation_id) { "export-1" }
      let(:student1)      { create(:student) }
      let(:student1_id)   { "export-2" }
      let(:student2)      { create(:student) }
      let(:student2_id)   { "export-3" }
      let(:mappings)      { {
        "suite_evaluations" => { evaluation_id => evaluation.id },
        "students"          => { student1_id    => student1.id, student2_id => student2.id }
      } }

      let(:exclude)     { [ ] }
      let(:input)  {
        Yajl.dump(
          attributes_for(:result).
          except(*exclude).
          merge(_evaluation_id: evaluation_id, _student_id: student1_id, _id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:result).
          except(*exclude).
          merge(_evaluation_id: evaluation_id, _student_id: student2_id, _id: "export-124")
        )
      }

      subject(:results) { Result.all }
      it                { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["results"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(results.collect(&:id)) }
      end
    end

    describe ".import_setting" do
      let(:method)        { :import_settings }

      let(:customizable)    { create(:suite) }
      let(:customizable_id) { "export-1" }
      let(:customizer1)      { create(:user) }
      let(:customizer1_id)   { "export-2" }
      let(:customizer2)      { create(:user) }
      let(:customizer2_id)   { "export-3" }
      let(:mappings)      { {
        "suites" => { customizable_id => customizable.id },
        "users"  => { customizer1_id  => customizer1.id, customizer2_id => customizer2.id }
      } }

      let(:exclude)     { [ :customizer, :customizable ] }
      let(:input)  {
        Yajl.dump(
          attributes_for(:setting).
          except(*exclude).
          merge(_customizable_id: customizable_id, customizable_type: "Suite", _customizer_id: customizer1_id, customizer_type: "User", _id: "export-123")
        ) +
        Yajl.dump(
          attributes_for(:setting).
          except(*exclude).
          merge(_customizable_id: customizable_id, customizable_type: "Suite", _customizer_id: customizer2_id, customizer_type: "User", _id: "export-124")
        )
      }

      subject(:settings) { Setting.all }
      it                 { should have(2).items }

      context "mappings" do
        subject      { importer.mappings["settings"] }
        its(:keys)   { should match_array(%w(export-123 export-124)) }
        its(:values) { should match_array(settings.collect(&:id)) }
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

    describe ".handle_participant_object" do
      let(:model)      { :participant }

      let(:suite)      { create(:suite) }
      let(:suite_id)   { "export-1" }
      let(:student)    { create(:student) }
      let(:student_id) { "export-2" }
      let(:group)      { create(:group) }
      let(:group_id)   { "export-3" }

      let(:meta)       {
        {
          _id:         "export-123",
          _suite_id:   suite_id,
          _student_id: student_id,
          _group_id:   group_id,
        }
      }

      let(:method)     { :handle_participant_object }

      before(:each) do
        importer.mappings["suites"]   = { suite_id   => suite.try(:id)   || 0 }
        importer.mappings["students"] = { student_id => student.try(:id) || 0 }
        importer.mappings["groups"]   = { group_id   => group.try(:id)   || 0 }
      end

      subject(:result) { importer.handle_participant_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }
      its(:suite)      { should == suite }
      its(:group)      { should == group }
      its(:student)    { should == student }

      context "without a group id" do
        let(:meta) {
          {
            _id:         "export-123",
            _suite_id:   suite_id,
            _student_id: student_id,
            _group_id:   nil,
          }
        }
        its(:group) { should be_nil }
      end
      context "without a suite" do
        let(:suite) { nil }
        it          { should be_nil }
      end
      context "without a student" do
        let(:student) { nil }
        it            { should be_nil }
      end
      context "without a group" do
        let(:group) { nil }
        it          { should be_nil }
      end
      context "with existing mapping" do
        before(:each) do
          participant = create(:participant, suite: suite, student: student, group: group)
          importer.mappings["participants"]["export-123"] = participant.id
        end
        it "does not create a new object" do
          result.should be_nil
          Participant.count(:all).should == 1
        end
      end
      context "with existing participant" do
        let!(:participant) { create(:participant, suite: suite, student: student) }
        it "does not create a new object" do
          result.should == participant
          Participant.count(:all).should == 1
        end
      end
    end

    describe ".handle_meeting_object" do
      let(:model)    { :meeting }

      let(:suite)    { create(:suite) }
      let(:suite_id) { "export-1" }

      let(:meta)     {
        {
          _id:         "export-123",
          _suite_id:   suite_id
        }
      }

      let(:method)   { :handle_meeting_object }

      before(:each) do
        importer.mappings["suites"] = { suite_id => suite.try(:id) || 0 }
      end

      subject(:result) { importer.handle_meeting_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }
      its(:suite)      { should == suite }

      context "without a suite" do
        let(:suite) { nil }
        it          { should be_nil }
      end
      context "with existing mapping" do
        before(:each) do
          meeting = create(:meeting, suite: suite)
          importer.mappings["meetings"]["export-123"] = meeting.id
        end
        it "does not create a new object" do
          result.should be_nil
          Meeting.count(:all).should == 1
        end
      end
    end

    describe ".handle_activity_object" do
      let(:model)      { :activity }
      let(:exclude)    { [ :meeting ] }

      let(:suite)      { create(:suite) }
      let(:suite_id)   { "export-1" }
      let(:meeting)    { create(:meeting) }
      let(:meeting_id) { "export-2" }

      let(:meta)       {
        {
          _id:         "export-123",
          _suite_id:   suite_id,
          _meeting_id: meeting_id
        }
      }

      let(:method)   { :handle_activity_object }

      before(:each) do
        importer.mappings["suites"]   = { suite_id   => suite.try(:id)   || 0 }
        importer.mappings["meetings"] = { meeting_id => meeting.try(:id) || 0 }
      end

      subject(:result) { importer.handle_activity_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }
      its(:suite)      { should == suite }
      its(:meeting)    { should == meeting }

      context "without a suite" do
        let(:suite) { nil }
        it          { should be_nil }
      end
      context "without a meeting" do
        let(:meeting) { nil }
        it            { should be_nil }
      end
      context "without a meeting id" do
        let(:meta) {
          {
            _id:         "export-123",
            _suite_id:   suite_id,
            _meeting_id: nil,
          }
        }
        its(:meeting) { should be_nil }
      end
      context "with existing mapping" do
        before(:each) do
          activity = create(:activity, suite: suite, meeting: meeting)
          importer.mappings["activities"]["export-123"] = activity.id
        end
        it "does not create a new object" do
          result.should be_nil
          Activity.count(:all).should == 1
        end
      end
    end

    describe ".handle_generic_evaluation_object" do
      let(:model)       { :generic_evaluation }
      let(:exclude)     { [
        :instance,
        :template,
        :suite,
        :red_min,
        :red_max,
        :yellow_min,
        :yellow_max,
        :green_min,
        :green_max,
        :stanine1_min,
        :stanine1_max,
        :stanine2_min,
        :stanine2_max,
        :stanine3_min,
        :stanine3_max,
        :stanine4_min,
        :stanine4_max,
        :stanine5_min,
        :stanine5_max,
        :stanine6_min,
        :stanine6_max,
        :stanine7_min,
        :stanine7_max,
        :stanine8_min,
        :stanine8_max,
        :stanine9_min,
        :stanine9_max,
      ] }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }

      let(:meta)        { { _id: "export-123", _instance_id: instance_id } }
      let(:method)      { :handle_generic_evaluation_object }

      before(:each) do
        importer.mappings["instances"] = { instance_id => instance.id }
      end

      subject(:result) { importer.handle_generic_evaluation_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }
      its(:instance)   { should == instance }

      context "with existing mapping" do
        before(:each) do
          generic_evaluation = create(:generic_evaluation)
          importer.mappings["generic_evaluations"]["export-123"] = generic_evaluation.id
        end
        it "does not create a new object" do
          result.should be_nil
          Evaluation.count(:all).should == 1
        end
      end
    end

    describe ".handle_evaluation_template_object" do
      let(:model)       { :evaluation_template }
      let(:exclude)     { [
        :instance,
        :template,
        :suite,
        :red_min,
        :red_max,
        :yellow_min,
        :yellow_max,
        :green_min,
        :green_max,
        :stanine1_min,
        :stanine1_max,
        :stanine2_min,
        :stanine2_max,
        :stanine3_min,
        :stanine3_max,
        :stanine4_min,
        :stanine4_max,
        :stanine5_min,
        :stanine5_max,
        :stanine6_min,
        :stanine6_max,
        :stanine7_min,
        :stanine7_max,
        :stanine8_min,
        :stanine8_max,
        :stanine9_min,
        :stanine9_max,
      ] }

      let(:instance)    { create(:instance) }
      let(:instance_id) { "export-1" }

      let(:meta)        { { _id: "export-123", _instance_id: instance_id } }
      let(:method)      { :handle_evaluation_template_object }

      before(:each) do
        importer.mappings["instances"] = { instance_id => instance.id }
      end

      subject(:result) { importer.handle_evaluation_template_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }
      its(:instance)   { should == instance }

      context "with existing mapping" do
        before(:each) do
          evaluation_template = create(:evaluation_template)
          importer.mappings["evaluation_templates"]["export-123"] = evaluation_template.id
        end
        it "does not create a new object" do
          result.should be_nil
          Evaluation.count(:all).should == 1
        end
      end
    end

    describe ".handle_evaluation_template_object_for_hierarchy" do
      let(:evaluation)   { create(:evaluation_template) }
      let(:template)     { create(:evaluation_template) }
      let(:_id)          { "export-13" }
      let(:_template_id) { "export-12" }
      let(:object)       { { _id: _id, _template_id: _template_id } }

      before(:each) do
        importer.mappings["evaluation_templates"] = {
          "export-12" => template,
          "export-13" => evaluation
        }
      end

      subject        { importer.handle_evaluation_template_object_for_hierarchy(object) }

      it             { should == evaluation }
      its(:template) { should == template }

      context "with no template id" do
        let(:_template_id) { nil }
        it               { should be_nil }
      end
      context "with existing template" do
        let(:evaluation) { create(:evaluation_template, template: create(:evaluation_template)) }
        it               { should     == evaluation }
        its(:template)   { should_not == template}
      end
    end

    describe ".handle_suite_evaluation_object" do
      let(:model)       { :suite_evaluation }
      let(:exclude)     { [
        :instance,
        :template,
        :suite,
        :red_min,
        :red_max,
        :yellow_min,
        :yellow_max,
        :green_min,
        :green_max,
        :stanine1_min,
        :stanine1_max,
        :stanine2_min,
        :stanine2_max,
        :stanine3_min,
        :stanine3_max,
        :stanine4_min,
        :stanine4_max,
        :stanine5_min,
        :stanine5_max,
        :stanine6_min,
        :stanine6_max,
        :stanine7_min,
        :stanine7_max,
        :stanine8_min,
        :stanine8_max,
        :stanine9_min,
        :stanine9_max,
      ] }

      let(:suite)       { create(:suite) }
      let(:suite_id)    { "export-2" }
      let(:template)    { create(:evaluation_template) }
      let(:template_id) { "export-3" }

      let(:meta)        { { _id: "export-123", _suite_id: suite_id, _template_id: template_id } }
      let(:method)      { :handle_suite_evaluation_object }

      before(:each) do
        importer.mappings["suites"]               = { suite_id    => suite.id }    if suite_id
        importer.mappings["evaluation_templates"] = { template_id => template.id } if template_id
      end

      subject(:result) { importer.handle_suite_evaluation_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.stringify_keys) }
      its(:suite)      { should == suite }
      its(:template)   { should == template }

      context "without template id" do
        let(:template_id) { nil }
        its(:template)    { should be_nil }
      end
      context "without template" do
        before(:each) do
          importer.mappings["evaluation_templates"] = { }
        end
        its(:template)    { should be_nil }
      end
      context "with existing mapping" do
        before(:each) do
          suite_evaluation = create(:suite_evaluation)
          importer.mappings["suite_evaluations"]["export-123"] = suite_evaluation.id
        end
        it "does not create a new object" do
          result.should be_nil
          Evaluation.with_type(:suite).count(:all).should == 1
        end
      end
    end

    describe ".handle_result_object" do
      let(:model)         { :result }
      let(:exclude)       { [ ] }

      let(:evaluation)    { create(:suite_evaluation) }
      let(:evaluation_id) { "export-1" }
      let(:student)       { create(:student) }
      let(:student_id)    { "export-2" }

      let(:meta)          { { _id: "export-123", _evaluation_id: evaluation_id, _student_id: student_id, color: :yellow } }
      let(:method)        { :handle_result_object }

      before(:each) do
        importer.mappings["suite_evaluations"] = { evaluation_id => evaluation.id } if evaluation_id
        importer.mappings["students"]          = { student_id    => student.id }    if student_id
      end

      subject(:result) { importer.handle_result_object(object) }

      it               { should_not be_new_record }
      its(:attributes) { should include(attributes.except(:color).stringify_keys) }
      its(:color)      { should == :yellow }
      its(:student)    { should == student }
      its(:evaluation) { should == evaluation }

      context "without evaluation" do
        before(:each) do
          importer.mappings["suite_evaluations"] = { }
        end
        it { should be_nil }
      end
      context "without student" do
        before(:each) do
          importer.mappings["students"] = { }
        end
        it { should be_nil }
      end
      context "with existing result" do
        let(:meta)       { {
          _id:            "export-123",
          _evaluation_id: evaluation_id,
          _student_id:    student_id,
          value:          0,
          color:          :red,
          created_at:     created_at
        } }
        let!(:existing_result) {
          create(:result,
            evaluation: evaluation,
            student:    student,
            value:      1,
            created_at: "2013-06-06T10:11:26+02:00"
          )
        }

        context "created before" do
          let(:created_at) { "2013-06-05T10:11:26+02:00" }
          it               { should == existing_result }
          its(:value)      { should == 1}
        end
        context "created after" do
          let(:created_at) { "2013-06-07T10:11:26+02:00" }
          it               { should == existing_result }
          its(:value)      { should == 0 }
        end
      end
      context "with existing mapping" do
        before(:each) do
          result = create(:result)
          importer.mappings["results"]["export-123"] = result.id
        end
        it "does not create a new object" do
          result.should be_nil
          Result.count(:all).should == 1
        end
      end
    end

    describe ".handle_setting_object" do
      let(:model)    { :setting }
      let(:exclude)  { [ :customizer, :customizable ] }

      let(:suite)    { create(:suite) }
      let(:suite_id) { "export-1" }
      let(:user)     { create(:user) }
      let(:user_id)  { "export-2" }

      let(:meta)     { {
        _id:               "export-123",
        _customizer_id:    user_id,
        customizer_type:   "User",
        _customizable_id:  suite_id,
        customizable_type: "Suite"
      } }
      let(:method)   { :handle_setting_object }

      before(:each) do
        importer.mappings["suites"] = { suite_id => suite.id } if suite_id
        importer.mappings["users"]  = { user_id  => user.id }  if user_id
      end

      subject(:setting)  { importer.handle_setting_object(object) }

      it                 { should_not be_new_record }
      its(:attributes)   { should include(attributes.stringify_keys) }
      its(:customizer)   { should == user }
      its(:customizable) { should == suite }

      context "without a customizer id" do
        let(:suite_id) { nil }
        it             { should be_nil }
      end
      context "without a customizable id" do
        let(:user_id) { nil }
        it            { should be_nil }
      end
      context "without a customizer" do
        before(:each) do
          importer.mappings["users"] = {}
        end
        it { should be_nil }
      end
      context "without a customizable" do
        before(:each) do
          importer.mappings["suites"] = {}
        end
        it { should be_nil }
      end
      context "with existing mapping" do
        before(:each) do
          importer.mappings["settings"]["export-123"] = create(:setting).id
        end
        it "does not create a new object" do
          setting.should be_nil
          Setting.count(:all).should == 1
        end
      end
    end
  end
end
