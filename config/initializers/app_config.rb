# Load application config from the files below
Conf = ConfigSpartan.create do
  %W(
  #{Rails.root}/config/app/base.yml
  #{Rails.root}/config/app/base.private.yml
  #{Rails.root}/config/app/#{Rails.env}.yml
  #{Rails.root}/config/app/#{Rails.env}.private.yml
  ).each do |f|
    file f if File.exists?(f)
  end
end
