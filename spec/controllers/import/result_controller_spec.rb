require 'spec_helper'

describe Import::ResultController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  describe "GET #new" do
    let!(:evaluation) { create(:suite_evaluation) }
    let!(:result)     { create(:result, evaluation: evaluation) }
    let!(:suite)      { evaluation.suite }
    let!(:student)    { result.student }

    it "is successful" do
      get :new
      expect(response).to be_success
    end

    it "is successful with specific suite" do
      get :new, suites: suite.id
      expect(response).to be_success
    end

    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns 401" do
        get :new
        expect(response.status).to be 401
      end
    end
  end

  describe "POST #confirm" do
    upload_file("results.csv", "")
    let!(:evaluation) { create(:suite_evaluation) }
    let(:filename)      { "#{timestamp.to_s(ActiveRecord::Base.cache_timestamp_format)}-#{uploaded_file.original_filename}" }
    let(:expected_file) { File.join(Rails.root, "tmp/uploads", filename) }
    let(:timestamp)     { Time.zone.now - 10.minutes }

    after(:each) do
      FileUtils.rm expected_file if File.exist?(expected_file)
    end

    it "copies the uploaded file to tmp/uploads and adds a timestamp to the name" do
      Timecop.freeze(timestamp) do
        post :confirm, csv_file: uploaded_file, evaluation: evaluation
      end

      expect(assigns(:filename)).to eq filename
      expect(assigns(:importer)).to be_a(Digilys::ResultImporter)
      expect(File.exist?(expected_file)).to be_true
    end

    it "handles errors" do
      post :confirm, csv_file: nil, evaluation: evaluation
      expect(flash[:error]).not_to be_empty
      expect(response).to redirect_to(new_import_result_path())

      post :confirm, csv_file: uploaded_file, evaluation: nil
      expect(flash[:error]).not_to be_empty
      expect(response).to redirect_to(new_import_result_path())
    end

    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns 401" do
        post :confirm, csv_file: uploaded_file, evaluation: evaluation
        expect(response.status).to be 401
      end
    end
  end

  describe "POST #create" do
    let(:student)      { create(:student, personal_id: "20000101-1234") }
    let(:participant)  { create(:participant, student: student) }
    let(:suite)        { participant.suite }
    let(:evaluation)   { create(:suite_evaluation, suite: suite, max_result: 10, _yellow: 4..7) }
    let(:particiapnts) { create_list(:participant, 1, suite: evaluation.suite) }

    let(:existing_student)      { create(:student, personal_id: "20000101-4321") }
    let(:existing_participant)  { create(:participant, student: existing_student, suite: suite) }

    context "with a correct file" do
      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-CSV.strip_heredoc
        20000101-1234,3
        CSV
      )

      it "imports data from the file" do
        expect(evaluation.results.count).to eq 0
        post :create, filename: File.basename(temp_file), evaluation: evaluation
        expect(evaluation.results.count).to eq 1
        expect(evaluation.results.first.value).to eq 3
        expect(response).to redirect_to(suite_path(suite))
      end
    end

    context "without an uploaded file" do
      let(:filename) { File.join(Rails.root, "tmp/uploads", "does-not-exist") }

      it "renders a 404" do
        expect(File.exist?(filename)).to be_false
        post :create, filename: filename, evaluation: evaluation
        expect(response.status).to be 404
      end
    end

    context "with an incorrect file" do
      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-CSV.strip_heredoc
        1
        CSV
      )

      it "redirects to the upload form with an error" do
        post :create, filename: File.basename(temp_file), evaluation: evaluation

        expect(response.status).to be 302
        expect(response).to redirect_to(new_import_result_path())
        expect(flash[:error]).not_to be_empty
      end
    end

    context "updating" do
      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-CSV.strip_heredoc
        20000101-4321,7
        CSV
      )

      it "should update existing" do
        evaluation.results.create!(student_id: existing_participant.student_id, value: 5)
        expect(evaluation.results.count).to eq 1
        expect(evaluation.results.first.value).to eq 5
        post :create, filename: File.basename(temp_file), evaluation: evaluation
        expect(evaluation.results.count).to eq 1
        expect(evaluation.results.first.value).to eq 7
        expect(response).to redirect_to(suite_path(suite))
      end
    end

    context "as instance admin" do
      login_user(:user)
      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-CSV.strip_heredoc
        20000101-4321,7
        CSV
      )

      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns 401" do
        post :create, filename: File.basename(temp_file), evaluation: evaluation
        expect(response.status).to be 401
      end
    end
  end
end
