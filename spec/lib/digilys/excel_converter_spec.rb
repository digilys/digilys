require 'spec_helper'
require 'digilys/excel_converter'

describe Digilys::ExcelConverter do
  let(:converter) { Digilys::ExcelConverter }

  describe "#convert_student_data_file" do
    let(:source_file) { File.join(Rails.root, "spec/fixtures/student_data.xlsx") }
    let(:target_file) { Tempfile.new([ "target", ".tsv" ]) }

    let(:result_rows) { CSV.read(target_file.path, col_sep: "\t") }

    let(:content) {
      <<-CSV.strip_heredoc
      School,Grade,Person ID,Last name,First name,Gender
      School1,Grade1,20000101-1234,Lastname,Firstname,Flicka
      CSV
    }

    before(:each) do
      target_file.close
    end
    after(:each) do
      target_file.unlink
    end

    it "only supports the files Roo supports" do
      expect { converter.convert_student_data_file("foo.txt", "foo2.txt") }.to raise_error
    end
    it "converts the source file to a tsv file" do
      converter.convert_student_data_file(source_file, target_file.path)
      expect(result_rows).to        have(3).items
      expect(result_rows.first).to  have(6).items
      expect(result_rows.second).to have(6).items
      expect(result_rows.third).to  have(6).items
    end
    it "supports an explicit extension" do
      converter.convert_student_data_file(source_file, target_file.path, ".xlsx")
      expect(result_rows).to have(3).items
    end

    it "converts person id floats to proper person ids" do
      converter.convert_student_data_file(source_file, target_file.path)
      expect(result_rows.second[2]).to eq "20010101-1234"
      expect(result_rows.third[2]).to  eq "010101-1235"
    end
    it "converts grade floats to integers" do
      converter.convert_student_data_file(source_file, target_file.path)
      expect(result_rows.second[1]).to eq "1"
      expect(result_rows.third[1]).to  eq "2"
    end
  end
end
