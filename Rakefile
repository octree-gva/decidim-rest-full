# frozen_string_literal: true

require "decidim/dev/common_rake"

def install_module(path)
  Dir.chdir(path) do
    system("bundle exec rake decidim_rest_full:install:migrations")
    system("bundle exec rails db:migrate")
  end
end

def seed_db(path)
  Dir.chdir(path) do
    system("bundle exec rake db:seed")
  end
end

##
# Tasks for test_app
##
def database_yml
  {

    "development" => {
      primary: {
        "adapter" => "postgres",
        "encoding" => "unicode",
        "host" => ENV.fetch("DATABASE_HOST", "localhost"),
        "port" => ENV.fetch("DATABASE_PORT", "5432").to_i,
        "username" => ENV.fetch("DATABASE_USERNAME", "decidim"),
        "password" => ENV.fetch("DATABASE_PASSWORD", "insecure-password"),
        "database" => "#{base_app_name}_development"
      }
    },
    "test" => {
      primary: {
        "adapter" => "postgres",
        "encoding" => "unicode",
        "host" => ENV.fetch("DATABASE_HOST", "localhost"),
        "port" => ENV.fetch("DATABASE_PORT", "5432").to_i,
        "username" => ENV.fetch("DATABASE_USERNAME", "decidim"),
        "password" => ENV.fetch("DATABASE_PASSWORD", "insecure-password"),
        "database" => "#{base_app_name}_test"
      }
    }
  }
end
desc "Prepare for testing"
task :prepare_tests do
  ENV["RAILS_ENV"] = "test"
  config_file = File.expand_path("spec/decidim_dummy_app/config/database.yml", __dir__)
  File.open(config_file, "w") { |f| YAML.dump(database_yml, f) }
  Dir.chdir("spec/decidim_dummy_app") do
    system("sed -i 's/config.cache_classes = true/config.cache_classes = false/' ./config/environments/test.rb")
    system("bundle exec rails db:migrate")
  end
end

desc "Generates a decidim_dummy_app app for testing"
task :test_app do
  puts "Generates spec/decidim_dummy_app"
  Bundler.with_original_env do
    generate_decidim_app(
      "spec/decidim_dummy_app",
      "--app_name",
      "decidim_rest_full",
      "--path",
      "../..",
      "--skip_spring",
      "--demo",
      "--force_ssl",
      "false",
      "--locales",
      "en,fr"
    )
  end

  puts "Setup DB config"
  Rake::Task["prepare_tests"].invoke
  puts "Install module"
  install_module("spec/decidim_dummy_app")
end

##
# Tasks for developement_app
##

desc "Prepare for development"
task :prepare_dev do
  # Remove previous existing db, and recreate one.
  Dir.chdir("development_app") do
    system("bundle exec rake db:drop")
    system("bundle exec rake db:create")
  end
  ENV["RAILS_ENV"] = "development"
  config_file = File.expand_path("development_app/config/database.yml", __dir__)
  File.open(config_file, "w") { |f| YAML.dump(database_yml, f) }
  Dir.chdir("development_app") do
    system("bundle exec rake db:migrate")
    system("npm install -D webpack-dev-server")
  end
end

desc "Generates a development app"
task :development_app do
  Bundler.with_original_env do
    generate_decidim_app(
      "development_app",
      "--app_name",
      base_app_name.to_s,
      "recreate_db",
      "--path",
      "..",
      "--skip_spring",
      "--demo",
      "--force_ssl",
      "false",
      "--demo"
    )
  end

  install_module("development_app")
  Rake::Task["prepare_dev"].invoke
end
