require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the SuitesHelper. For example:
#
# describe SuitesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end
describe SuitesHelper do
  context "#calendar_entries" do
    let(:suite) { create(:suite) }
    subject { helper.calendar_entries(suite) }

    context "without entites" do
      it { should be_empty }
    end

    context "with entities" do
      let(:entities) do
        [
          create(:evaluation, suite: suite, date: Date.yesterday),
          create(:evaluation, suite: suite, date: Date.today),
          create(:evaluation, suite: suite, date: Date.tomorrow),
          create(:meeting,    suite: suite, date: Date.yesterday),
          create(:meeting,    suite: suite, date: Date.today),
          create(:meeting,    suite: suite, date: Date.tomorrow)
        ]
      end

      it { should match_array(entities) }

      it "sorts the collection by the entities's date" do
        prev = nil
        subject.each do |e|
          e.date.should >= prev.date unless prev.nil?
          prev = e
        end
      end
    end
  end
end
