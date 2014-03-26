require 'spec_helper'

describe CacheObserver do

  subject(:observer) { CacheObserver.instance }

  def changed(*models)
    observer.changed_models = models
  end

  context "activity touching" do
    let(:activity) { create(:activity) }
    let(:suite)    { activity.suite }
    before(:each)  { changed(activity) }

    it "touches the activity's suite" do
      expect { observer.handle_changes }.to touch(suite)
    end
  end

  context "evaluation touching" do
    let(:evaluation)  { create(:suite_evaluation) }
    let(:suite)       { evaluation.suite }
    let(:color_table) { evaluation.suite.color_table }
    before(:each)     { changed(evaluation) }

    it "touches the evaluation's suite" do
      expect { observer.handle_changes }.to touch(suite)
    end
    it "touches the evaluation's suite's color table" do
      expect { observer.handle_changes }.to touch(color_table)
    end

    context "for standalone color tables" do
      let(:color_table) { create(:color_table, evaluations: [evaluation]) }

      context "with a generic evaluation" do
        let(:evaluation) { create(:generic_evaluation) }
        it "touches the color table" do
          expect { observer.handle_changes }.to touch(color_table)
        end
      end
      context "with a suite evaluation" do
        it "touches the color table" do
          expect { observer.handle_changes }.to touch(color_table)
        end
      end
    end
  end

  context "meeting touching" do
    let(:meeting) { create(:meeting) }
    let(:suite)   { meeting.suite }
    before(:each) { changed(meeting) }

    it "touches the meeting's suite" do
      expect { observer.handle_changes }.to touch(suite)
    end
  end

  context "participant touching" do
    let(:participant) { create(:participant) }
    let(:suite)       { participant.suite }
    before(:each)     { changed(participant) }

    it "touches the participant's suite" do
      expect { observer.handle_changes }.to touch(suite)
    end
  end

  context "result touching" do
    let(:result)     { create(:result, evaluation: evaluation) }
    let(:evaluation) { create(:suite_evaluation) }
    let(:suite)      { evaluation.suite }
    let(:student)    { result.student }
    before(:each)    { changed(result) }

    it "touches the result's evaluation" do
      expect { observer.handle_changes }.to touch(evaluation)
    end
    it "touches the result's evaluation's suite" do
      expect { observer.handle_changes }.to touch(suite)
    end
    it "touches the result's student" do
      expect { observer.handle_changes }.to touch(student)
    end
  end

  context "table state touching" do
    let(:table_state) { create(:table_state) }
    let(:color_table) { table_state.base }
    before(:each)     { changed(table_state) }

    it "touches the participant's suite" do
      expect { observer.handle_changes }.to touch(color_table)
    end
  end

  context "student touching" do
    let(:student)            { create(:student) }
    let(:generic_evaluation) { create(:generic_evaluation) }
    let(:generic_result)     { create(:result, student: student, evaluation: generic_evaluation) }
    let(:participant)        { create(:participant, student: student) }
    let(:suite)              { participant.suite }
    let(:color_table)        { create(:color_table, evaluations: [generic_evaluation]) }
    before(:each)            { changed(student) }

    it "touches the student's suites" do
      expect { observer.handle_changes }.to touch(suite)
    end
    it "touches the student's color tables" do
      generic_result
      expect { observer.handle_changes }.to touch(color_table)
    end
  end

  context "group touching" do
    let(:group)       { create(:group) }
    let(:student)     { create(:student) }
    let(:participant) { create(:participant, student: student) }
    let(:suite)       { participant.suite }

    before(:each) do
      group.add_students(student)
      changed(group)
    end

    it "touches the group's indirect suites" do
      expect { observer.handle_changes }.to touch(suite)
    end
  end
end
