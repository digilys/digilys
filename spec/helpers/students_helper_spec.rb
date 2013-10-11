require 'spec_helper'

describe StudentsHelper do
  describe "#student_name" do
    let(:student)    { build(:student, first_name: "zomg", last_name: "lol") }
    let(:name_order) { :first_name }
    before(:each)    { helper.stub(:current_user).and_return(build(:user, name_ordering: name_order)) }

    subject          { helper.student_name(student) }
    it               { should == "zomg lol" }

    context "reversed" do
      let(:name_order) { :last_name }
      it               { should == "lol, zomg" }
    end
  end
end
