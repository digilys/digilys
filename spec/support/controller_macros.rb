module ControllerMacros
  def temp_file(path, content)
    let(:_orig_temp_file) { Tempfile.new("tempfile") }
    let(:temp_file)       { File.join(path, File.basename(_orig_temp_file.path)) }

    before(:each) do
      begin
        _orig_temp_file.write(content)
      ensure
        _orig_temp_file.close
      end
      FileUtils.mv _orig_temp_file.path, temp_file
    end
    after(:each) do
      FileUtils.rm temp_file if File.exist?(temp_file)
    end
  end

  def upload_file(name, content)
    let(:temp_file)     { Tempfile.new(name.to_s) }
    let(:uploaded_file) { Rack::Test::UploadedFile.new(temp_file.path) }

    before(:each) do
      begin
        temp_file.write(content)
      ensure
        temp_file.close
      end
    end
    after(:each) do
      temp_file.unlink
    end
  end
end
