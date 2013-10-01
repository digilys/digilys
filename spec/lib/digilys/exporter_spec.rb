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
end
