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

  describe "#working_with_import?" do
    let(:params) { { controller: controller_name } }
    before       { helper.stub(:params).and_return(params) }
    subject      { helper.working_with_import? }

    context "under import namespace" do
      let(:controller_name) { "import/foo" }
      it                    { should be_true }
    end
    context "under other namespace" do
      let(:controller_name) { "imports/foo" }
      it                    { should be_false }
    end
    context "under no namespace" do
      let(:controller_name) { "importfoo" }
      it                    { should be_false }
    end
  end

  describe "#confirm_destroy_form" do
    before(:each) do
      helper.stub(:render) { |options| options }
    end

    let(:entity)   { create(:suite) }
    let(:message)  { "Destroy confirmation message" }
    let(:options)  { {} }
    let(:rendered) { helper.confirm_destroy_form(entity, message, options) }

    subject { rendered }

    it { should include(partial: "shared/confirm_destroy_form") }
    
    context "locals" do
      subject { rendered[:locals] }

      it { should include(entity:       entity) }
      it { should include(message:      message) }
      it { should include(cancel_path:  helper.url_for(entity)) }

      context "with cancel_to entity" do
        let(:cancel_to) { create(:evaluation) }
        let(:options)   { { cancel_to: cancel_to }}

        it { should include(cancel_path: helper.url_for(cancel_to)) }
      end
    end
  end

  describe "#simple_search_form" do
    before(:each) do
      helper.stub(:url_for).and_return("/form/target")
    end

    subject { helper.simple_search_form(:name_cont) }
    it      { should     have_selector("input[name='q[name_cont]']") }
    it      { should     have_selector("form[action='/form/target']") }
    it      { should_not have_selector("a[href='/form/target']") }

    context "with existing params" do
      before(:each) do
        helper.stub(:params).and_return(q: { name_cont: "name" })
        it { should_not have_selector("a[href='/form/target']") }
      end
    end
  end

  context "google chart helpers" do
    before(:each) do
      helper.should_receive(:content_for).at_least(:once).with(:page_end, anything()) do |target, html|
        html
      end
    end
    describe "#gchart_init" do
      subject(:html) { Capybara::Node::Simple.new(helper.gchart_init) }
      it { should have_selector("script", count: 2, visible: false)}
      it { should have_selector("script[src='//google.com/jsapi']", visible: false)}
      it { should have_content(%(google.load("visualization", "1.0", {"packages": ["corechart"]});)) }
    end
    describe "#gchart" do
      subject(:html) { Capybara::Node::Simple.new(
        helper.gchart(
          id: "foo",
          type: :line,
          url: "zomg",
          foo: "bar"
        )
      ) }
      it { should have_selector("script", visible: false) }
      it { should have_content(%(document.getElementById("foo"))) }
      it { should have_content("new google.visualization.LineChart") }
      it { should have_content("$.getJSON(\"zomg\"") }
      it { should have_content("chart.draw(google.visualization.arrayToDataTable(data), #{{foo: "bar"}.to_json});")}
    end
  end
end
