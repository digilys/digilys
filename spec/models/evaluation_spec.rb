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

    context "with regular suite" do
      subject { build(:evaluation, suite: create(:suite, is_template: false)) }
      it { should validate_presence_of(:date) }
      it { should     allow_value("2013-04-29").for(:date) }
      it { should_not allow_value("201304-29").for(:date) }
    end
  end

  context ".has_regular_suite?" do
    context "with no suite" do
      subject { build(:evaluation, suite: nil).has_regular_suite? }
      it { should be_false }
    end
    context "with template suite" do
      subject { build(:evaluation, suite: create(:suite, is_template: true)).has_regular_suite? }
      it { should be_false }
    end
    context "with regular suite" do
      subject { build(:evaluation, suite: create(:suite, is_template: false)).has_regular_suite? }
      it { should be_true }
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
    let(:template) { create(:evaluation) }
    subject        { Evaluation.new_from_template(template) }

    its(:template_id) { should == template.id }
    its(:name)        { should == template.name }
    its(:max_result)  { should == template.max_result }
    its(:red_below)   { should == template.red_below }
    its(:green_above) { should == template.green_above }

    1.upto(8).each do |i|
      its(:"stanine#{i}") { should == template.send(:"stanine#{i}") }
    end

    context "with attrs" do
      subject { Evaluation.new_from_template(template, { suite_id: 1, name: "Overridden" }) }
      its(:suite_id) { should == 1 }
      its(:name)     { should == "Overridden" }
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
