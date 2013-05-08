require 'spec_helper'

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

  describe ".format_range" do
    it "joins ranges with a html ndash" do
      helper.format_range(10..20).should == "10 &ndash; 20"
    end
    it "handles single values" do
      helper.format_range(10).should == 10
    end
  end
end
