require 'spec_helper'
require 'digilys/evaluation_template_importer'

describe Digilys::EvaluationTemplateImporter do
  let(:csv)             { "" }
  let(:instance)        { create(:instance) }
  let(:update_existing) { false }
  let(:has_header_row)  { false }

  subject(:importer)    { Digilys::EvaluationTemplateImporter.new(CSV.new(csv), instance.id, update_existing, has_header_row) }

  describe ".parsed_attributes" do
    let(:csv) {
      <<-CSV.strip_heredoc
      Template1,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
      CSV
    }

    subject(:parsed_attributes) { importer.parsed_attributes }

    it { should have(1).items }

    context "original row" do
      subject { parsed_attributes.first[:original_row] }
      it { should == %w(Template1 Template1\ desc foo,\ bar 50 0-24 25-39 40-50 0 0 0 1-9 10-19 20-29 30-39 40-44 45-50) }
    end
    context "attributes" do
      subject { parsed_attributes.first[:attributes] }

      its(:keys) { should have(16).items }

      it { should include(name: "Template1") }
      it { should include(description: "Template1 desc") }
      it { should include(category_list: "foo, bar") }
      it { should include(max_result: 50) }
      it { should include(red: 0..24) }
      it { should include(yellow: 25..39) }
      it { should include(green: 40..50) }
      it { should include(stanine1: 0..0) }
      it { should include(stanine2: 0..0) }
      it { should include(stanine3: 0..0) }
      it { should include(stanine4: 1..9) }
      it { should include(stanine5: 10..19) }
      it { should include(stanine6: 20..29) }
      it { should include(stanine7: 30..39) }
      it { should include(stanine8: 40..44) }
      it { should include(stanine9: 45..50) }
    end

    context "with header row" do
      let(:has_header_row) { true }
      let(:csv) {
        <<-CSV.strip_heredoc
        Name,Description,Categories,Max,Red,Yellow,Green,Stanine1,Stanine2,Stanine3,Stanine4,Stanine5,Stanine6,Stanine7,Stanine8,Stanine9
        Template1,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
        CSV
      }

      subject(:parsed_attributes) { importer.parsed_attributes }

      it { should have(1).items }
    end

    context "with non breaking spaces" do
      let(:csv) {
        <<-CSV.strip_heredoc
        Template\u00A01,Template1\u00A0desc,"foo,\u00A0bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
        CSV
      }
      subject { parsed_attributes.first[:attributes] }
      it { should include(name: "Template 1") }
      it { should include(description: "Template1 desc") }
      it { should include(category_list: "foo, bar") }
    end

    context "with color percentages" do
      let(:csv) {
        <<-CSV.strip_heredoc
        Template1,Template1 desc,"foo, bar",50,0-33%,34-66%,67-100%,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
        CSV
      }
      subject { parsed_attributes.first[:attributes] }

      it { should include(yellow: 17..33) }
      it { should include(red: 0..16) }
      it { should include(green: 34..50) }

      context "in reverse order" do
        let(:csv) {
          <<-CSV.strip_heredoc
          Template1,Template1 desc,"foo, bar",50,67-100%,34-66%,0-33%,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
          CSV
        }
        subject { parsed_attributes.first[:attributes] }

        it { should include(yellow: 17..33) }
        it { should include(green: 0..16) }
        it { should include(red: 34..50) }
      end
    end

    context "with different types of intervals" do
      let(:csv) {
        <<-CSV.strip_heredoc
        Template1,Template1 desc,"foo, bar",50,-24,25-39,40-,0,0,,1-9,10-19,20-29,30-39,40-44,45-50
        CSV
      }
      subject { parsed_attributes.first[:attributes] }

      it { should include(red: 0..24) }
      it { should include(green: 40..50) }
      it { should include(stanine1: 0..0) }
      it { should include(stanine3: nil) }
    end
  end

  describe ".valid?" do
    context "with valid rows" do
      let(:csv) {
        <<-CSV.strip_heredoc
        Template1,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
        Template2,Template2 desc,"foo, bar",50,0-24,25-39,40-50
        CSV
      }

      it { should be_valid }
    end
    context "with invalid rows" do
      let(:csv) {
        <<-CSV.strip_heredoc
        ,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
        Template2,Template2 desc,"foo, bar",50,0-24,25-39,40-50
        CSV
      }

      it { should_not be_valid }
    end
  end
  describe "count methods" do
    let(:update_existing) { true }
    let(:csv) {
      <<-CSV.strip_heredoc
      ,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
      Template2,Template2 desc,"foo, bar",50,0-24,25-39,40-50
      CSV
    }

    before(:each) do
      create(:evaluation_template, name: "Template2", description: "Template2 desc", instance: instance, imported: true)
      importer.valid?
    end

    its(:valid_count)   { should == 1 }
    its(:invalid_count) { should == 1 }
    its(:update_count)  { should == 1 }
  end

  describe ".invalid" do
    let(:csv) {
      <<-CSV.strip_heredoc
      ,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
      CSV
    }

    before(:each) do
      importer.valid?
    end

    subject { importer.invalid }

    it { should have(1).items }

    context "content" do
      subject { importer.invalid.first }
      it { should have_key(:original_row) }
      it { should have_key(:attributes) }
      it { should have_key(:model) }
    end
    context "model" do
      subject { importer.invalid.first[:model] }
      it      { should be_a(Evaluation) }
      it      { should_not be_valid }
      it      { should have(1).error_on(:name) }
    end
  end

  describe ".import!" do
    let(:update_existing) { true }
    let(:csv) {
      <<-CSV.strip_heredoc
      Template1,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
      Template2,Template2 desc,"foo, bar",50,0-24,25-39,40-50
      CSV
    }

    it "saves evaluation templates" do
      Evaluation.count.should == 0

      importer.import!

      Evaluation.count.should == 2

      # First
      e = Evaluation.where(name: "Template1").first

      e.instance_id.should   == instance.id
      e.imported.should      be_true
      e.value_type.should    == "numeric"
      e.target.should        == "all"
      e.type.should          == "template"
      e.description.should   == "Template1 desc"
      e.category_list.should match_array(%w(foo bar))
      e.max_result.should    == 50
      e.red_min.should       == 0
      e.red_max.should       == 24
      e.yellow_min.should    == 25
      e.yellow_max.should    == 39
      e.green_min.should     == 40
      e.green_max.should     == 50
      e.stanine1_min.should  == 0
      e.stanine1_max.should  == 0
      e.stanine2_min.should  == 0
      e.stanine2_max.should  == 0
      e.stanine3_min.should  == 0
      e.stanine3_max.should  == 0
      e.stanine4_min.should  == 1
      e.stanine4_max.should  == 9
      e.stanine5_min.should  == 10
      e.stanine5_max.should  == 19
      e.stanine6_min.should  == 20
      e.stanine6_max.should  == 29
      e.stanine7_min.should  == 30
      e.stanine7_max.should  == 39
      e.stanine8_min.should  == 40
      e.stanine8_max.should  == 44
      e.stanine9_min.should  == 45
      e.stanine9_max.should  == 50

      # Second
      e = Evaluation.where(name: "Template2").first

      e.instance_id.should   == instance.id
      e.imported.should      be_true
      e.value_type.should    == "numeric"
      e.target.should        == "all"
      e.type.should          == "template"
      e.description.should   == "Template2 desc"
      e.category_list.should match_array(%w(foo bar))
      e.max_result.should    == 50
      e.red_min.should       == 0
      e.red_max.should       == 24
      e.yellow_min.should    == 25
      e.yellow_max.should    == 39
      e.green_min.should     == 40
      e.green_max.should     == 50
      e.stanine1_min.should  be_nil
      e.stanine1_max.should  be_nil
      e.stanine2_min.should  be_nil
      e.stanine2_max.should  be_nil
      e.stanine3_min.should  be_nil
      e.stanine3_max.should  be_nil
      e.stanine4_min.should  be_nil
      e.stanine4_max.should  be_nil
      e.stanine5_min.should  be_nil
      e.stanine5_max.should  be_nil
      e.stanine6_min.should  be_nil
      e.stanine6_max.should  be_nil
      e.stanine7_min.should  be_nil
      e.stanine7_max.should  be_nil
      e.stanine8_min.should  be_nil
      e.stanine8_max.should  be_nil
      e.stanine9_min.should  be_nil
      e.stanine9_max.should  be_nil
    end

    context "with existing" do
      before(:each) do
        create(
          :evaluation_template,
          instance:      instance,
          imported:      true,
          name:          "Template1",
          description:   "Template1 desc",
          category_list: "apa,bepa",
          max_result:    30,
          _yellow:       10..20,
          _stanines:     nil
        )
      end

      it "saves evaluation templates" do
        Evaluation.count.should == 1

        importer.import!

        Evaluation.count.should == 2

        # First
        e = Evaluation.where(name: "Template1").first

        e.instance_id.should   == instance.id
        e.imported.should      be_true
        e.value_type.should    == "numeric"
        e.target.should        == "all"
        e.type.should          == "template"
        e.description.should   == "Template1 desc"
        e.category_list.should match_array(%w(foo bar))
        e.max_result.should    == 50
        e.red_min.should       == 0
        e.red_max.should       == 24
        e.yellow_min.should    == 25
        e.yellow_max.should    == 39
        e.green_min.should     == 40
        e.green_max.should     == 50
        e.stanine1_min.should  == 0
        e.stanine1_max.should  == 0
        e.stanine2_min.should  == 0
        e.stanine2_max.should  == 0
        e.stanine3_min.should  == 0
        e.stanine3_max.should  == 0
        e.stanine4_min.should  == 1
        e.stanine4_max.should  == 9
        e.stanine5_min.should  == 10
        e.stanine5_max.should  == 19
        e.stanine6_min.should  == 20
        e.stanine6_max.should  == 29
        e.stanine7_min.should  == 30
        e.stanine7_max.should  == 39
        e.stanine8_min.should  == 40
        e.stanine8_max.should  == 44
        e.stanine9_min.should  == 45
        e.stanine9_max.should  == 50
      end
    end
  end
end
