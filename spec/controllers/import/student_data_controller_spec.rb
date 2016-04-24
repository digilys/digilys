require 'spec_helper'

describe Import::StudentDataController, versioning: !ENV["debug_versioning"].blank? do
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
      it "is successful" do
        get :new
        expect(response).to be_successful
      end
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

      expect(assigns(:filename)).to eq filename
      expect(assigns(:importer)).to be_a(Digilys::StudentDataImporter)
      expect(File.exist?(expected_file)).to be_true
    end

    it "handles errors" do
      post :confirm, excel_file: nil
      expect(response).to redirect_to(new_import_student_data_url())
      expect(flash[:error]).not_to be_empty
    end

    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "is successful" do
        Timecop.freeze(timestamp) do
          post :confirm,
            excel_file: fixture_file_upload(
              "/student_data.xlsx",
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            )
        end

        expect(assigns(:filename)).to eq filename
        expect(assigns(:importer)).to be_a(Digilys::StudentDataImporter)
        expect(File.exist?(expected_file)).to be_true
      end
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
        expect(Student.count).to eq 0
        expect(Group.count).to   eq 0
        post :create, filename: File.basename(temp_file)
        expect(response).to redirect_to(students_url())
        expect(Student.count).to eq 1
        expect(Group.count).to   eq 2
      end
      context "as instance admin" do
        login_user(:user)
        before(:each) do
          logged_in_user.admin_instance = logged_in_user.active_instance
          logged_in_user.save
        end
        it "imports data from the file" do
          expect(Student.count).to eq 0
          expect(Group.count).to   eq 0
          post :create, filename: File.basename(temp_file)
          expect(response).to redirect_to(students_url())
          expect(Student.count).to eq 1
          expect(Group.count).to   eq 2
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
        <<-TSV
      \t\t\t\t\t
      School1\tGrade1\t\tFirst name\tLast name\tFlicka
      TSV
      )

      it "redirects back to the upload form with an error" do
        post :create, filename: File.basename(temp_file)
        expect(flash[:error]).not_to be_empty
        expect(response).to redirect_to(new_import_student_data_url())
      end
    end
  end
end
