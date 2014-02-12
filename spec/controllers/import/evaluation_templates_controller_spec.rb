require 'spec_helper'

describe Import::EvaluationTemplatesController do
  login_user(:admin)

  describe "GET #new" do
    it "is successful" do
      get :new
      response.should be_success
    end
  end

  describe "POST #confirm" do
    upload_file("evaluation_templates.csv", "")
    let(:filename)      { "#{timestamp.to_s(ActiveRecord::Base.cache_timestamp_format)}-#{uploaded_file.original_filename}" }
    let(:expected_file) { File.join(Rails.root, "tmp/uploads", filename) }
    let(:timestamp)     { Time.zone.now - 10.minutes }

    after(:each) do
      FileUtils.rm expected_file if File.exist?(expected_file)
    end

    it "copies the uploaded file to tmp/uploads and adds a timestamp to the name" do
      Timecop.freeze(timestamp) do
        post :confirm, csv_file: uploaded_file
      end

      assigns(:filename).should == filename
      assigns(:importer).should be_a(Digilys::EvaluationTemplateImporter)
      File.exist?(expected_file).should be_true
    end
    it "handles errors" do
      post :confirm, csv_file: nil
      flash[:error].should_not be_empty
      response.should redirect_to(new_import_evaluation_template_url())
    end
  end

  describe "POST #create" do
    context "with a correct file" do
      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-CSV.strip_heredoc
      ,,,,,,,,,,,,,,,
      Template1,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
      CSV
      )

      it "imports data from the file" do
        Evaluation.count.should == 0
        post :create, filename: File.basename(temp_file)
        response.should redirect_to(template_evaluations_url())
        Evaluation.count.should == 1
      end
    end
    context "without an uploaded file" do
      let(:filename) { File.join(Rails.root, "tmp/uploads", "does-not-exist") }

      it "renders a 404" do
        File.exist?(filename).should be_false
        post :create, filename: filename
        response.status.should == 404
      end
    end
    context "with an incorrect file" do
      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-CSV.strip_heredoc
      ,,,,,,,,,,,,,,,
      ,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
      CSV
      )

      it "redirects to the upload form with an error" do
        post :create, filename: File.basename(temp_file)
        flash[:error].should_not be_empty
        response.should redirect_to(new_import_evaluation_template_url())
      end
    end
  end
end
