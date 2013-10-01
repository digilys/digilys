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
end
