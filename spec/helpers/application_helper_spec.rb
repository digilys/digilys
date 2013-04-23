require 'spec_helper'

describe ApplicationHelper do
  describe "#bootstrap_flash" do
    it "does not print anything when there are no flash messages" do
      helper.bootstrap_flash.should be_blank
    end
    it "only prints flash messages that have been set" do
      flash[:error] = "Error message"
      flash[:info]  = "Info message"
      result        = helper.bootstrap_flash
      result.should     match(/Error message/)
      result.should     match(/Info message/)
      result.should_not match(/alert-(success|warning)/)
    end
    it "uses bootstrap classes" do
      flash[:error] = "Error message"
      result        = helper.bootstrap_flash
      result.should match(/class="[^"]*\balert[^-][^"]*"/)
      result.should match(/class="[^"]*\balert-error[^"]*"/)
    end
  end

  describe "#active_if" do
    it "returns \"active\" if the argument evaluates to true" do
      helper.active_if(true).should == "active"
    end
    it "returns \"\" if the argument evaluates to false" do
      helper.active_if(false).should be_blank
    end
  end

  describe "#params?" do
    let(:params) { { "controller" => "foo", "action" => "bar", "other" => "zomg" } }
    before { helper.stub(:params).and_return(params) }

    it "returns true if supplied parameters exist in params" do
      helper.params?(controller: "foo").should  be_true
      helper.params?(action:     "bar").should  be_true
      helper.params?(other:      "zomg").should be_true
      helper.params?(
        controller: "foo",
        action:     "bar"
      ).should be_true
      helper.params?(
        action: "bar",
        other:  "zomg"
      ).should be_true
    end
    it "returns false if any supplied parameters is missing params" do
      helper.params?(controller: "err").should be_false
      helper.params?(action:     "err").should be_false
      helper.params?(other:      "err").should be_false
      helper.params?(
        controller: "foo",
        action:     "bar",
        other:      "err"
      ).should be_false
      helper.params?(
        action: "err",
        other:  "zomg"
      ).should be_false
    end
    it "handles multiple parameter hashes, returning active if any of the hashes match" do
      helper.params?({ controller: "err" }, { controller: "foo"  }).should be_true
      helper.params?({ controller: "err" }, { controller: "err2" }).should be_false
    end
  end
end
