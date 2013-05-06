require 'spec_helper'

describe Evaluation do
  context "factory" do
    subject { build(:evaluation) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:date) }
    it { should allow_mass_assignment_of(:max_result) }
    it { should allow_mass_assignment_of(:red_below) }
    it { should allow_mass_assignment_of(:green_above) }
    it { should allow_mass_assignment_of(:stanine1) }
    it { should allow_mass_assignment_of(:stanine2) }
    it { should allow_mass_assignment_of(:stanine3) }
    it { should allow_mass_assignment_of(:stanine4) }
    it { should allow_mass_assignment_of(:stanine5) }
    it { should allow_mass_assignment_of(:stanine6) }
    it { should allow_mass_assignment_of(:stanine7) }
    it { should allow_mass_assignment_of(:stanine8) }
  end
  context "validation" do
    it { should     validate_presence_of(:name) }
    it { should_not validate_presence_of(:date) }

    it { should validate_numericality_of(:max_result).only_integer }
    it { should validate_numericality_of(:red_below).only_integer }
    it { should validate_numericality_of(:green_above).only_integer }

    it { should validate_numericality_of(:stanine1).only_integer }
    it { should validate_numericality_of(:stanine2).only_integer }
    it { should validate_numericality_of(:stanine3).only_integer }
    it { should validate_numericality_of(:stanine4).only_integer }
    it { should validate_numericality_of(:stanine5).only_integer }
    it { should validate_numericality_of(:stanine6).only_integer }
    it { should validate_numericality_of(:stanine7).only_integer }
    it { should validate_numericality_of(:stanine8).only_integer }

    it { should_not allow_value(-1).for(:max_result) }

    context "limit ranges" do
      subject { build(:evaluation, max_result: 50, red_below: 20, green_above: 30) }
      it { should_not allow_value(-1).for(:red_below) }
      it { should_not allow_value(51).for(:green_above) }
      it { should_not allow_value(19).for(:green_above) }
      it { should_not allow_value(31).for(:red_below) }
    end

    context "stanine" do
      context "with stanines" do
        let(:stanine_limits) { [10,20,30,40,50,60,70,80] }
        subject { build(:evaluation, max_result: 90, stanines: stanine_limits)}

        # 8 stanine limits
        1.upto(8).each do |i|
          it { should_not allow_value(nil).for(:"stanine#{i}") }
          it { should_not allow_value(-1).for(:"stanine#{i}") }
          it { should_not allow_value(stanine_limits[i - 2] - 1).for(:"stanine#{i}") }   if i > 1
          it { should_not allow_value(stanine_limits[i]     + 1).for(:"stanine#{i}") }   if i < 8
        end
      end

      context "without stanines" do
        subject { build(:evaluation, max_result: 90, stanines: Array.new(8) )}
        it { should be_valid }
      end
    end

    context "with suite" do
      subject { build(:evaluation, suite: create(:suite)) }
      it { should validate_presence_of(:date) }
      it { should     allow_value("2013-04-29").for(:date) }
      it { should_not allow_value("201304-29").for(:date) }
    end
  end

  context ".result_for" do
    let(:students)   { create_list(:student, 3) }
    let(:student)    { students.second }
    let(:evaluation) { create(:evaluation) }
    before           { students.each_with_index { |student, i| create(:result, evaluation: evaluation, student: student, value: (i+1)*10) } }

    it "returns the correct result" do
      evaluation.result_for(student).value.should == 20
    end
    it "returns nil when the result cannot be found" do
      evaluation.result_for(create(:student)).should be_nil
    end
  end

  context ".stanines" do
    let(:stanine_limits) { [ 10, 20, 30, 40, 50, 60, 70, 80 ] }
    let(:evaluation)     { create(:evaluation, max_result: 90, stanines: stanine_limits )}
    it "returns an array with the stanine boundaries" do
      evaluation.stanines.should == stanine_limits
    end
  end

  context ".stanines?" do
    it "returns true if all stanine values are set" do
      create(:evaluation, stanines: Array.new(8, 1)).stanines?.should be_true
    end
    it "stanines are " do
      create(:evaluation, stanines: Array.new(8)).stanines?.should be_false
    end
  end

  context "#new_from_template" do
    let(:template)   { create(:evaluation) }
    let(:evaluation) { Evaluation.new_from_template(template) }
    describe "template_id" do
      subject { evaluation.template_id }
      it { should == template.id }
    end
    describe "name" do
      subject { evaluation.name }
      it { should == template.name }
    end
    describe "max_result" do
      subject { evaluation.max_result }
      it { should == template.max_result }
    end
    describe "red_below" do
      subject { evaluation.red_below }
      it { should == template.red_below }
    end
    describe "green_above" do
      subject { evaluation.green_above }
      it { should == template.green_above }
    end
    1.upto(8).each do |i|
      describe "stanine#{i}" do
        subject { evaluation.send(:"stanine#{i}") }
        it { should == template.send(:"stanine#{i}") }
      end
    end

    context "with attrs" do
      let(:evaluation) { Evaluation.new_from_template(template, { suite_id: 1, name: "Overridden" }) }
      describe "extra attributes" do
        subject { evaluation.suite_id }
        it { should == 1 }
      end
      describe "overridden attributes" do
        subject { evaluation.name }
        it { should == "Overridden" }
      end
    end
  end

  context "#templates" do
    let!(:templates) { create_list(:evaluation,            3) }
    let!(:regular)   { create_list(:evaluation_with_suite, 3) }
    it "should scope to templates only" do
      Evaluation.templates.all.should match_array(templates)
    end
  end
end
