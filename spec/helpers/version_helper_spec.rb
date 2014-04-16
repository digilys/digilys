require 'spec_helper'

describe VersionHelper do
  describe "#listify" do
    it "displays nothing if there are no elements in the list" do
      expect(listify([])).to be_blank
    end
    it "returns the element if the list only has one element" do
      expect(listify(%w(foo))).to eq "foo"
    end
    it "wraps all elements in a html list" do
      expect(listify(%w(foo b<a>r baz))).to eq "<ul><li>foo</li><li>b&lt;a&gt;r</li><li>baz</li></ul>"
    end
    it "supports options for the list" do
      expect(listify(%w(foo bar), class: "unstyled")).to start_with('<ul class="unstyled">')
    end
  end

  describe "#version_item_link" do
    let(:item) { build(:suite) }

    before(:each) do
      helper.stub(:link_to).and_return { |text, url| { text: text, url: url } }
    end

    it "links to the version's item" do
      version = double("PaperTrail::Version", item: item)
      expect(helper.version_item_link(version)).to eq({ text: item.name, url: item })
    end

    it "links to the student when the item is a participant" do
      participant = create(:participant)
      version = double("PaperTrail::Version", item: participant)
      expect(helper.version_item_link(version)).to eq({ text: participant.student.name, url: participant.student })
    end

    it "returns just a name for a deleted object" do
      version = double("PaperTrail::Version", attributes: { "object" => nil }, item: nil, object: %({"name":"Foo"}))
      expect(helper.version_item_link(version)).to eq "Foo"
    end
    it "returns just a name for a deleted object where only a changeset exists" do
      version = double("PaperTrail::Version", attributes: { "object" => nil }, item: nil, object: nil, changeset: { "name" => [ nil, "Foo" ] })
      expect(helper.version_item_link(version)).to eq "Foo"
    end

    it "tries to load the student for the deleted object" do
      student = create(:student)
      version = double("PaperTrail::Version", attributes: { "object" => nil }, item: nil, object: %({"student_id":#{student.id}}))
      expect(helper.version_item_link(version)).to eq({ text: student.name, url: student })
    end

    it "tries to load the student from the changeset for the deleted object if there is no object" do
      student = create(:student)
      version = double("PaperTrail::Version", attributes: { "object" => nil }, item: nil, object: nil, changeset: { "student_id" => [ nil, student.id ] })
      expect(helper.version_item_link(version)).to eq({ text: student.name, url: student })
    end
  end


  def create_version(item, event, changeset = {})
    double(
      "PaperTrail::Version",
      item:      item,
      item_type: item.class.to_s,
      item_id:   item.id,
      event:     event.to_s,
      changeset: changeset.stringify_keys
    )
  end

  describe "#version_events" do
    it "dispatches suite versions to #version_events_for_suite" do
      helper.should_receive(:version_events_for_suite)
      helper.version_events(create_version(build(:suite), :create))
    end
    it "dispatches evaluation versions to #version_events_for_evaluation" do
      helper.should_receive(:version_events_for_evaluation)
      helper.version_events(create_version(build(:evaluation), :create))
    end
    it "dispatches meeting versions to #version_events_for_meeting" do
      helper.should_receive(:version_events_for_meeting)
      helper.version_events(create_version(build(:meeting), :create))
    end
    it "dispatches activity versions to #version_events_for_activity" do
      helper.should_receive(:version_events_for_activity)
      helper.version_events(create_version(build(:activity), :create))
    end
    it "dispatches participant versions to #version_events_for_participant" do
      helper.should_receive(:version_events_for_participant)
      helper.version_events(create_version(build(:participant), :create))
    end
    it "returns blank when receiving an unknown version" do
      expect(helper.version_events(create_version(build(:instance), :create))).to be_blank
    end
  end

  describe "#version_events_for_suite" do
    let(:suite) { build(:suite) }
    it "displays a text for a create event" do
      result = version_events_for_suite(create_version(suite, :create))
      expect(result).to match_array([ t(:"events.suite.created") ])
    end
    it "includes a text when updating the name" do
      result = version_events_for_suite(create_version(suite, :update, { name: %w(foo bar) }))
      expect(result).to include(t(:"events.suite.name_changed", from: "foo", to: "bar"))
    end
  end

  describe "#version_events_for_evaluation" do
    let(:evaluation) { build(:suite_evaluation) }
    it "displays a text for a create event" do
      result = version_events_for_evaluation(create_version(evaluation, :create))
      expect(result).to match_array([ t(:"events.evaluation.created", name: evaluation.name) ])
    end
    it "includes a text when updating the name" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { name: %w(foo bar) }))
      expect(result).to include(t(:"events.evaluation.name_changed", name: evaluation.name, from: "foo", to: "bar"))
    end
    it "includes a text when updating the max result" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { max_result: [1,2] }))
      expect(result).to include(t(:"events.evaluation.max_result_changed", max_result: evaluation.max_result, from: 1, to: 2))
    end
    it "includes a text when updating the date" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { date: %w(2014-03-01 2014-03-02) }))
      expect(result).to include(t(:"events.evaluation.date_changed", date: evaluation.date, from: "2014-03-01", to: "2014-03-02"))
    end
    it "includes a text when updating the description" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { description: %w(foo bar) }))
      expect(result).to include(t(:"events.evaluation.description_changed", description: evaluation.description, from: "foo", to: "bar"))
    end
    it "includes a text when updating the target" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { target: %w(all female) }))
      expect(result).to include(t(:"events.evaluation.target_changed", target: evaluation.target, from: t(:"enumerize.evaluation.target.all"), to: t(:"enumerize.evaluation.target.female")))
    end
    it "includes a text when updating the colors" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { colors: %w(foo bar) }))
      expect(result).to include(t(:"events.evaluation.colors_changed", colors: evaluation.colors))
    end
    it "includes a text when updating the stanines" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { stanines: %w(foo bar) }))
      expect(result).to include(t(:"events.evaluation.stanines_changed", stanines: evaluation.stanines))
    end
    it "includes a text for when the status is changed to empty" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { status: %w(partial empty) }))
      expect(result).to include(t(:"events.evaluation.status_empty"))
    end
    it "includes a text for when the status is changed to partial" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { status: %w(empty partial) }))
      expect(result).to include(t(:"events.evaluation.status_partial"))
    end
    it "includes a text for when the status is changed to complete" do
      result = version_events_for_evaluation(create_version(evaluation, :update, { status: %w(empty complete) }))
      expect(result).to include(t(:"events.evaluation.status_complete"))
    end
  end

  describe "#version_events_for_meeting" do
    let(:meeting) { build(:meeting) }
    it "displays a text for a create event" do
      result = version_events_for_meeting(create_version(meeting, :create))
      expect(result).to match_array([ t(:"events.meeting.created") ])
    end
    it "includes a text when updating the name" do
      result = version_events_for_meeting(create_version(meeting, :update, { name: %w(foo bar) }))
      expect(result).to include(t(:"events.meeting.name_changed", from: "foo", to: "bar"))
    end
    it "includes a text when updating the date" do
      result = version_events_for_meeting(create_version(meeting, :update, { date: %w(2014-03-01 2014-03-02) }))
      expect(result).to include(t(:"events.meeting.date_changed", from: "2014-03-01", to: "2014-03-02"))
    end
    it "includes a text when completing the meeting" do
      result = version_events_for_meeting(create_version(meeting, :update, { completed: [false, true] }))
      expect(result).to include(t(:"events.meeting.completed"))
    end
    it "includes a text when uncompleting the meeting" do
      result = version_events_for_meeting(create_version(meeting, :update, { completed: [true, false] }))
      expect(result).to include(t(:"events.meeting.uncompleted"))
    end
  end

  describe "#version_events_for_activity" do
    let(:activity) { build(:activity) }
    it "displays a text for a create event" do
      result = version_events_for_activity(create_version(activity, :create))
      expect(result).to match_array([ t(:"events.activity.created") ])
    end
    it "includes a text when updating the name" do
      result = version_events_for_activity(create_version(activity, :update, { name: %w(foo bar) }))
      expect(result).to include(t(:"events.activity.name_changed", from: "foo", to: "bar"))
    end
    it "includes a text when updating the start date" do
      result = version_events_for_activity(create_version(activity, :update, { start_date: %w(2014-03-01 2014-03-02) }))
      expect(result).to include(t(:"events.activity.start_date_changed", from: "2014-03-01", to: "2014-03-02"))
    end
    it "includes a text when updating the end date" do
      result = version_events_for_activity(create_version(activity, :update, { end_date: %w(2014-03-01 2014-03-02) }))
      expect(result).to include(t(:"events.activity.end_date_changed", from: "2014-03-01", to: "2014-03-02"))
    end
    it "includes a text when closing the activity" do
      result = version_events_for_activity(create_version(activity, :update, { status: ["open", "closed"] }))
      expect(result).to include(t(:"events.activity.closed"))
    end
    it "includes a text when opening the activity" do
      result = version_events_for_activity(create_version(activity, :update, { status: ["closed", "open"] }))
      expect(result).to include(t(:"events.activity.open"))
    end
  end

  describe "#version_events_for_participant" do
    let(:participant) { build(:participant) }
    it "displays a text for a create event" do
      result = version_events_for_participant(create_version(participant, :create))
      expect(result).to match_array([ t(:"events.participant.created") ])
    end
    it "displays a text for a destroy event" do
      result = version_events_for_participant(create_version(participant, :destroy))
      expect(result).to match_array([ t(:"events.participant.destroyed") ])
    end
  end
end
