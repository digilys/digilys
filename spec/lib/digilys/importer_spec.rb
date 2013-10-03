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

    before(:each) do
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
  end

  context "handlers" do
    let(:attributes) {
      attributes_for(model).merge(
        created_at: Time.zone.now - 2.hours,
        updated_at: Time.zone.now - 1.hour
      )
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
  end
end
