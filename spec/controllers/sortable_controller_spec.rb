require 'spec_helper'

describe SortableController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance)    { create(:instance) }
  let(:suite)       { create(:suite) }
  let(:other_suite) { create(:suite, instance: instance) }

  describe "POST #reorder suite's evaluations" do

    let!(:suite)           { create(:suite) }
    let!(:evaluation_1)    { create(:suite_evaluation, suite: suite, position: 1) }
    let!(:evaluation_2)    { create(:suite_evaluation, suite: suite, position: 2) }
    let!(:evaluation_3)    { create(:suite_evaluation, suite: suite, position: 3) }
    before(:each) do
      request.env['HTTP_REFERER'] = "/suites/#{suite.id}"
    end

    it "should reorder evaluations" do
      post :reorder, evaluation: [evaluation_3.id, evaluation_1.id, evaluation_2.id]
      expect(evaluation_3.reload.position).to eq 0
      expect(evaluation_1.reload.position).to eq 1
      expect(evaluation_2.reload.position).to eq 2
    end

  end
end
