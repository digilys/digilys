source "https://rubygems.org"

gem "rails",               "3.2.13"
gem "pg",                  "~> 0.15.1"
gem "dalli",               "~> 2.6.4"
gem "haml-rails",          "~> 0.4"
gem "rails_admin",         "~> 0.4.7"
gem "devise",              "~> 2.2.3"
gem "cancan",              "~> 1.6.9"
gem "rolify",              "~> 3.2.0"
gem "kaminari",            "~> 0.14.1"
gem "config_spartan",      "~> 1.0.1"
gem "ransack",             "~> 0.7.2"
gem "acts-as-taggable-on", "~> 2.4.1"
gem "enumerize",           "~> 0.6.1"

gem "yubikey_database_authenticatable",
  git: "https://github.com/mort666/yubikey_database_authenticatable",
  ref: "a8d2ff86928fc342a99dc4974e7f3cbee390f01b"

gem "roo", "~> 1.13.2"

# Servers
gem "passenger", "~> 3.0.19", require: false

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem "sass-rails",   "~> 3.2.3"
  gem "coffee-rails", "~> 3.2.1"
  gem "uglifier",     ">= 1.0.3"
  gem "therubyracer", "~> 0.11.4", require: "v8"
end

gem "jquery-rails",                    "~> 2.2.1"
gem "bootstrap-sass",                  "~> 2.3.1.0"
gem "kaminari-bootstrap",              "~> 0.1.3"
gem "formtastic-bootstrap",            "~> 2.1.1"
gem "select2-rails",                   "~> 3.5.0"
gem "bootstrap-datepicker-rails",      "~> 1.0.0.5"
gem "tinymce-rails",                   "~> 4.0.2"
gem "tinymce-rails-langs",             "~> 4.20130625"
gem "jquery-datatables-rails",         "~> 1.11.2"
gem "jasny_bootstrap_extension_rails", "~> 0.0.1"

gem "yajl-ruby", "~> 1.1.0", require: "yajl"

group :development do
  gem "capistrano", "~> 2.14.2"
end
group :test, :development do
  gem "pry",                "~> 0.9.12"
  gem "pry-remote",         "~> 0.1.7"
  gem "rspec-rails",        "~> 2.0"
  gem "factory_girl",       "~> 4.2.0"
  gem "factory_girl_rails", "~> 4.2.1"
  gem "capybara",           "~> 2.1.0"
  gem "jasmine-rails",      "~> 0.4.6"
end
group :test do
  gem "shoulda-matchers", "~> 2.4.0"
  gem "timecop",          "~> 0.6.3"
  gem 'simplecov',        "~> 0.8.2", require: false
end

