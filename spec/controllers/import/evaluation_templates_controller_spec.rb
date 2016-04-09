require 'spec_helper'

describe Import::EvaluationTemplatesController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  describe "GET #new" do
    it "is successful" do
      get :new
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

      expect(assigns(:filename)).to eq filename
      expect(assigns(:importer)).to be_a(Digilys::EvaluationTemplateImporter)
      expect(File.exist?(expected_file)).to be_true
    end
    it "handles errors" do
      post :confirm, csv_file: nil
      expect(flash[:error]).not_to be_empty
      expect(response).to redirect_to(new_import_evaluation_template_url())
    end
    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns 401" do
        Timecop.freeze(timestamp) do
          post :confirm, csv_file: uploaded_file
        end
        expect(response.status).to be 401
      end
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
        expect(Evaluation.count).to eq 0
        post :create, filename: File.basename(temp_file)
        expect(response).to redirect_to(template_evaluations_url())
        expect(Evaluation.count).to eq 1
      end
      context "as instance admin" do
        login_user(:user)
        before(:each) do
          logged_in_user.admin_instance = logged_in_user.active_instance
          logged_in_user.save
        end
        it "returns 401" do
          post :create, filename: File.basename(temp_file)
          expect(response.status).to be 401
        end
      end
    end
    context "without an uploaded file" do
      let(:filename) { File.join(Rails.root, "tmp/uploads", "does-not-exist") }

      it "renders a 404" do
        expect(File.exist?(filename)).to be_false
        post :create, filename: filename
        expect(response.status).to be 404
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
        expect(flash[:error]).not_to be_empty
        expect(response).to redirect_to(new_import_evaluation_template_url())
      end
    end

    context "updating" do
      let(:instance) { create(:instance) }

      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-CSV.strip_heredoc
      ,,,,,,,,,,,,,,,
      Template1,Template1 desc,"foo, bar",50,0-24,25-39,40-50,0,0,0,1-9,10-19,20-29,30-39,40-44,45-50
      CSV
      )

      let!(:existing) { create(
        :evaluation_template,
        name: "Template1",
        description: "Template1 desc",
        instance: instance,
        imported: true,
        max_result: 100
      ) }

      before(:each) do
        controller.stub(:current_instance_id).and_return(instance.id)
      end

      it "should update existing if required" do
        post :create, filename: File.basename(temp_file), update: "1"
        expect(Evaluation.count).to eq 1
        expect(existing.reload.max_result).to eq 50
      end
      it "should not update existing by default" do
        post :create, filename: File.basename(temp_file)
        expect(Evaluation.count).to eq 2
      end
    end
  end
end
