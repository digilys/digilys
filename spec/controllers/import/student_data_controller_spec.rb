require 'spec_helper'

describe Import::StudentDataController do
  login_user(:admin)

  describe "GET #new" do
    it "is successful" do
      get :new
      response.should be_success
    end
  end

  describe "POST #confirm" do
    let(:timestamp)     { Time.zone.now - 10.minutes }
    let(:filename)      { "#{timestamp.to_s(ActiveRecord::Base.cache_timestamp_format)}-student_data.xlsx.tsv" }
    let(:expected_file) { File.join(Rails.root, "tmp/uploads", filename) }

    after(:each) do
      FileUtils.rm expected_file if File.exist?(expected_file)
    end

    it "converts the uploaded file using the Excel converter" do
      Timecop.freeze(timestamp) do
        post :confirm,
          excel_file: fixture_file_upload(
            "/student_data.xlsx",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          )
      end

      assigns(:filename).should == filename
      assigns(:importer).should be_a(Digilys::StudentDataImporter)
      File.exist?(expected_file).should be_true
    end
    
    it "handles errors" do
      post :confirm, excel_file: nil
      response.should redirect_to(new_import_student_data_url())
      flash[:error].should_not be_empty
    end
  end

  describe "POST #create" do
    context "with a correct file" do
      temp_file(
        File.join(Rails.root, "tmp/uploads"),
        <<-TSV
      \t\t\t\t\t
      School1\tGrade1\t20000101-1234\tFirst name\tLast name\tFlicka
      TSV
      )

      it "imports data from the file" do
        Student.count.should == 0
        Group.count.should   == 0
        post :create, filename: File.basename(temp_file)
        response.should redirect_to(students_url())
        Student.count.should == 1
        Group.count.should   == 2
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
        <<-TSV
      \t\t\t\t\t
      School1\tGrade1\t\tFirst name\tLast name\tFlicka
      TSV
      )

      it "redirects back to the upload form with an error" do
        post :create, filename: File.basename(temp_file)
        flash[:error].should_not be_empty
        response.should redirect_to(new_import_student_data_url())
      end
    end
  end
end
