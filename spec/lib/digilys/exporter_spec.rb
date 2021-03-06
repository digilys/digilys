require 'spec_helper'
require 'digilys/exporter'

describe Digilys::Exporter do
  let(:id_prefix) { "export" }
  let(:method)    { nil }

  subject(:result) do
    io = StringIO.new

    Digilys::Exporter.new(id_prefix).send(method, io)

    objs = []
    Yajl::Parser.parse(io.string) { |obj| objs << obj }

    objs.length == 1 ? objs.first : objs
  end

  describe ".export_instances" do
    let(:method) { :export_instances }

    context "format" do
      let!(:instance) { create(:instance) }
      it              { should include("_id" => "export-#{instance.id}") }
      it              { should include(instance.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at)$/ }) }
    end
    context "multiple" do
      let!(:instances) { create_list(:instance, 2) }
      it               { should have(2).items }
    end
  end

  describe ".export_users" do
    let(:method) { :export_users }

    context "format" do
      let!(:user) { create(:user) }
      it          { should include("_id" => "export-#{user.id}") }
      it          { should include("_active_instance_id" => "export-#{user.active_instance_id}") }
      it          { should include(user.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|active_instance_id)$/ }) }
    end
    context "multiple" do
      let!(:user) { create_list(:user, 2) }
      it          { should have(2).items }
    end
  end

  describe ".export_students" do
    let(:method) { :export_students }

    context "format" do
      let!(:student) { create(:student, data: {foo: "bar"}) }
      it             { should include("_id" => "export-#{student.id}") }
      it             { should include("_instance_id" => "export-#{student.instance_id}") }
      it             { should include("personal_id" => "export-#{student.personal_id}") }
      it             { should include(student.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at)$/ }) }

      it "deserializes serialized fields" do
        expect(result["data"]).to be_instance_of(Hash)
      end
    end
    context "multiple" do
      let!(:students) { create_list(:student, 2) }
      it              { should have(2).items }
    end
  end

  describe ".export_groups" do
    let(:method) { :export_groups }

    context "format" do
      let!(:group) { create(:group, parent_id: 0) }
      it           { should include("_id" => "export-#{group.id}") }
      it           { should include("_parent_id" => "export-0") }
      it           { should include(group.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at)$/ }) }
      it           { should include("_students") }
      it           { should include("_users") }

      context "with students" do
        let(:students) { create_list(:student, 2) }
        before(:each) do
          group.students = students
        end

        subject { result["_students"] }
        it      { should match_array(students.collect { |s| "export-#{s.id}" }) }
      end
      context "with users" do
        let(:users) { create_list(:user, 2) }
        before(:each) do
          group.users = users
        end

        subject { result["_users"] }
        it      { should match_array(users.collect { |s| "export-#{s.id}" }) }
      end
    end
    context "multiple" do
      let!(:groups) { create_list(:group, 2) }
      it            { should have(2).items }
    end
  end

  describe ".export_instructions" do
    let(:method) { :export_instructions }

    context "format" do
      let!(:instruction) { create(:instruction) }
      it                 { should include("_id" => "export-#{instruction.id}") }
      it                 { should include(instruction.attributes.reject { |k,v| k =~ /^(id|created_at|updated_at)$/ }) }
    end
    context "multiple" do
      let!(:instructions) { create_list(:instruction, 2) }
      it                  { should have(2).items }
    end
  end

  describe ".export_suites" do
    let(:method) { :export_suites }

    context "format" do
      let!(:suite) { create(:suite, template_id: 0, generic_evaluations: [ 1,2,3 ]) }
      it           { should include("_id" => "export-#{suite.id}") }
      it           { should include("_template_id" => "export-#{suite.template_id}") }
      it           { should include("_instance_id" => "export-#{suite.instance_id}") }
      it           { should include("generic_evaluations" => %w(export-1 export-2 export-3)) }
      it           { should include(suite.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|generic_evaluations)$/ }) }
    end
    context "multiple" do
      let!(:suites) { create_list(:suite, 2) }
      it            { should have(2).items }
    end
  end

  describe ".export_participants" do
    let(:method) { :export_participants }

    context "format" do
      let!(:participant) { create(:participant, group: create(:group)) }
      it                 { should include("_id" => "export-#{participant.id}") }
      it                 { should include("_suite_id" => "export-#{participant.suite_id}") }
      it                 { should include("_student_id" => "export-#{participant.student_id}") }
      it                 { should include("_group_id" => "export-#{participant.group_id}") }
    end
    context "multiple" do
      let!(:participants) { create_list(:participant, 2) }
      it                  { should have(2).items }
    end
  end

  describe ".export_meetings" do
    let(:method) { :export_meetings }

    context "format" do
      let!(:meeting) { create(:meeting) }
      it             { should include("_id" => "export-#{meeting.id}") }
      it             { should include("_suite_id" => "export-#{meeting.suite_id}") }
      it             { should include(meeting.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|date)$/ }) }
      it "should have the correct date" do
        expect(result["date"]).to eq meeting.date.to_s
      end
    end
    context "multiple" do
      let!(:meetings) { create_list(:meeting, 2) }
      it              { should have(2).items }
    end
  end

  describe ".export_activities" do
    let(:method) { :export_activities }

    context "format" do
      let!(:activity) { create(:activity, meeting: create(:meeting), start_date: Date.yesterday, end_date: Date.tomorrow) }
      it              { should include("_id" => "export-#{activity.id}") }
      it              { should include("_suite_id" => "export-#{activity.suite_id}") }
      it              { should include("_meeting_id" => "export-#{activity.meeting_id}") }
      it              { should include(activity.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|.*_date)$/ }) }
      it "should have the correct dates" do
        expect(result["start_date"]).to eq activity.start_date.to_s
        expect(result["end_date"]).to   eq activity.end_date.to_s
      end

      context "with groups" do
        let(:groups) { create_list(:group, 2) }
        before(:each) do
          activity.groups = groups
        end

        subject { result["_groups"] }
        it      { should match_array(groups.collect { |g| "export-#{g.id}"}) }
      end
      context "with students" do
        let(:students) { create_list(:student, 2) }
        before(:each) do
          activity.students = students
        end

        subject { result["_students"] }
        it      { should match_array(students.collect { |g| "export-#{g.id}"}) }
      end
      context "with users" do
        let(:users) { create_list(:user, 2) }
        before(:each) do
          activity.users = users
        end

        subject { result["_users"] }
        it      { should match_array(users.collect { |g| "export-#{g.id}"}) }
      end
    end
    context "multiple" do
      let!(:activities) { create_list(:activity, 2) }
      it                { should have(2).items }
    end
  end

  describe ".export_generic_evaluations" do
    let(:method) { :export_generic_evaluations }

    context "format" do
      let!(:generic_evaluation) { create(:generic_evaluation, template_id: 0, category_list: "foo,bar,baz") }
      it                        { should include("_id" => "export-#{generic_evaluation.id}") }
      it                        { should include("_instance_id" => "export-#{generic_evaluation.instance_id}") }
      it                        { should include("_suite_id" => nil) }
      it                        { should include("_template_id" => "export-0") }
      it                        { should include("date" => nil) }
      it                        { should include(generic_evaluation.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|date)$/ }) }
      it "should include the categories" do
        expect(result["category_list"]).to match_array(%w(foo bar baz))
      end
    end
    context "multiple" do
      let!(:generic_evaluations) { create_list(:generic_evaluation, 2) }
      it                         { should have(2).items }
    end
  end

  describe ".export_evaluation_templates" do
    let(:method) { :export_evaluation_templates }

    context "format" do
      let!(:evaluation_template) { create(:evaluation_template, template_id: 0, category_list: "foo,bar,baz") }
      it                         { should include("_id" => "export-#{evaluation_template.id}") }
      it                         { should include("_instance_id" => "export-#{evaluation_template.instance_id}") }
      it                         { should include("_suite_id" => nil) }
      it                         { should include("_template_id" => "export-0") }
      it                         { should include("date" => nil) }
      it                         { should include(evaluation_template.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|date)$/ }) }
      it "should include the categories" do
        expect(result["category_list"]).to match_array(%w(foo bar baz))
      end
    end
    context "multiple" do
      let!(:evaluation_templates) { create_list(:evaluation_template, 2) }
      it                          { should have(2).items }
    end
  end

  describe ".export_suite_evaluations" do
    let(:method) { :export_suite_evaluations }

    context "format" do
      let!(:suite_evaluation) { create(:suite_evaluation, template_id: 0, category_list: "foo,bar,baz") }
      it                      { should include("_id" => "export-#{suite_evaluation.id}") }
      it                      { should include("_instance_id" => nil) }
      it                      { should include("_suite_id" => "export-#{suite_evaluation.suite_id}") }
      it                      { should include("_template_id" => "export-0") }
      it                      { should include("date" => suite_evaluation.date.to_s) }
      it                      { should include(suite_evaluation.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|date)$/ }) }
      it "should include the categories" do
        expect(result["category_list"]).to match_array(%w(foo bar baz))
      end

      context "with participants" do
        let(:participants) { create_list(:participant, 2, suite: suite_evaluation.suite) }
        before(:each) do
          suite_evaluation.evaluation_participants = participants
        end

        subject { result["_participants"] }
        it      { should match_array(participants.collect { |s| "export-#{s.id}" }) }
      end
      context "with users" do
        let(:users) { create_list(:user, 2) }
        before(:each) do
          suite_evaluation.users = users
        end

        subject { result["_users"] }
        it      { should match_array(users.collect { |s| "export-#{s.id}" }) }
      end
    end
    context "multiple" do
      let!(:suite_evaluations) { create_list(:suite_evaluation, 2) }
      it                       { should have(2).items }
    end
  end

  describe ".export_results" do
    let(:method) { :export_results }

    context "format" do
      let!(:res) { create(:result) }
      it         { should include("_id" => "export-#{res.id}") }
      it         { should include("_evaluation_id" => "export-#{res.evaluation_id}") }
      it         { should include("_student_id" => "export-#{res.student_id}") }
      it         { should include("color" => res.color.to_s) }
      it         { should include(res.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|color)$/ }) }
    end
    context "multiple" do
      let!(:results) { create_list(:result, 2) }
      it             { should have(2).items }
    end
  end

  describe ".export_settings" do
    let(:method) { :export_settings }

    context "format" do
      let!(:setting) { create(:setting) }
      it             { should include("_id" => "export-#{setting.id}") }
      it             { should include("_customizer_id" => "export-#{setting.customizer_id}") }
      it             { should include("_customizable_id" => "export-#{setting.customizable_id}") }
      it             { should include(setting.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at)$/ }) }
    end
    context "multiple" do
      let!(:settings) { create_list(:setting, 2) }
      it              { should have(2).items }
    end
  end

  describe ".export_table_states" do
    let(:method) { :export_table_states }

    context "format" do
      let!(:table_state) { create(:table_state) }
      it                 { should include("_id" => "export-#{table_state.id}") }
      it                 { should include("_base_id" => "export-#{table_state.base_id}") }
      it                 { should include(table_state.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at)$/ }) }
    end
    context "multiple" do
      let!(:table_states) { create_list(:table_state, 2) }
      it                  { should have(2).items }
    end
  end

  describe ".export_roles" do
    let(:method) { :export_roles }

    let(:user) { create(:user) }

    context "format" do
      context "for global" do
        before(:each) do
          user.add_role    :admin
          user.remove_role :member, user.active_instance
        end
        it { should include("name"          => "admin") }
        it { should include("resource_type" => nil) }
        it { should include("_resource_id"  => nil) }
        it { should include("_users"        => ["export-#{user.id}"]) }
      end
      context "for model" do
        before(:each) do
          Role.delete_all()
          user.add_role    :manager, Suite
          user.remove_role :member,  user.active_instance
        end
        it { should include("name"          => "manager") }
        it { should include("resource_type" => "Suite") }
        it { should include("_resource_id"  => nil) }
        it { should include("_users"        => ["export-#{user.id}"]) }
      end
      context "for object" do
        before(:each) do
          Role.delete_all()
          user
        end
        it { should include("name"          => "member") }
        it { should include("resource_type" => "Instance") }
        it { should include("_resource_id"  => "export-#{user.active_instance_id}") }
        it { should include("_users"        => ["export-#{user.id}"]) }
      end
    end
    context "multiple" do
      before(:each) do
        user.add_role :admin
        # One role from the active instance membership
      end
      it { should have(2).items }
    end
  end
end
