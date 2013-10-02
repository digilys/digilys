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
      it              { should include(instance.attributes.reject { |k,v| k =~ /^(id|created_at|updated_at)$/ }) }
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
      it          { should include(user.attributes.reject { |k,v| k =~ /^(id|created_at|updated_at|active_instance_id)$/ }) }
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
        result["data"].should be_instance_of(Hash)
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

  describe ".export_meetings" do
    let(:method) { :export_meetings }

    context "format" do
      let!(:meeting) { create(:meeting) }
      it             { should include("_id" => "export-#{meeting.id}") }
      it             { should include("_suite_id" => "export-#{meeting.suite_id}") }
      it             { should include(meeting.attributes.reject { |k,v| k =~ /^(id|.*_id|created_at|updated_at|date)$/ }) }
      it "should have the correct date" do
        result["date"].should == meeting.date.to_s
      end
    end
    context "multiple" do
      let!(:meetings) { create_list(:meeting, 2) }
      it              { should have(2).items }
    end
  end
end
