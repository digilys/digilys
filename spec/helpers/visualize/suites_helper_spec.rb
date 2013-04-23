require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the Visualize::SuitesHelper. For example:
#
# describe Visualize::SuitesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end
describe Visualize::SuitesHelper do
  describe ".result_color_class" do
    it "handles nil results" do
      helper.result_color_class(nil).should be_blank
    end

    let(:evaluation) { create(:evaluation, max_result: 20, red_below: 10, green_above: 15) }

    context "for red result" do
      let(:result) { create(:result, value: 5, evaluation: evaluation) }
      it "returns red" do
        helper.result_color_class(result).should == "result-red"
      end
    end
    context "for yellow result" do
      let(:result) { create(:result, value: 12, evaluation: evaluation) }
      it "returns yellow" do
        helper.result_color_class(result).should == "result-yellow"
      end
    end
    context "for green result" do
      let(:result) { create(:result, value: 18, evaluation: evaluation) }
      it "returns green" do
        helper.result_color_class(result).should == "result-green"
      end
    end
  end
end
