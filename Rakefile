# frozen_string_literal: true

require "decidim/dev/common_rake"
require "rspec/core/rake_task"

def install_module(path)
  Dir.chdir(path) do
    system("bundle check || bundle install")
    system("bundle exec rake decidim_rest_full:install:migrations")
    system("bundle exec rake db:create db:migrate")
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
    "adapter" => "postgresql",
    "encoding" => "unicode",
    "host" => ENV.fetch("DATABASE_HOST", "localhost"),
    "port" => ENV.fetch("DATABASE_PORT", "5432").to_i,
    "username" => ENV.fetch("DATABASE_USERNAME", "decidim"),
    "password" => ENV.fetch("DATABASE_PASSWORD", "insecure-password"),
    "database" => "decidim_module_rest_full_test_app_test"
  }
end
desc "Prepare for testing"
task :prepare_tests do
  ENV["RAILS_ENV"] = "test"
  config_file = File.expand_path("spec/decidim_dummy_app/config/database.yml", __dir__)
  File.open(config_file, "w") { |f| YAML.dump({ "test" => database_yml, "development" => database_yml }, f) }
  dummy_root = File.expand_path("spec/decidim_dummy_app", __dir__)
  Dir.chdir(dummy_root) do
    system("sed -i 's/config.cache_classes = true/config.cache_classes = false/' ./config/environments/test.rb")
  end
  # Mount RestFull engine before Core so its config/routes.rb runs first and registers API routes on Core.
  routes_file = File.join(dummy_root, "config/routes.rb")
  routes_content = File.read(routes_file)
  rest_full_line = "  mount Decidim::RestFull::Engine => '/'\n"
  routes_content.gsub!(/^\s*mount Decidim::RestFull::Engine.*\n/, "")
  unless routes_content.include?("mount Decidim::RestFull::Engine")
    routes_content.sub!(%r{^(\s*mount Decidim::Core::Engine => '/'.*\n)}, "#{rest_full_line}\\1")
    File.write(routes_file, routes_content)
  end
end

desc "Generates a decidim_dummy_app app for testing"
task :test_app do
  puts "Generates spec/decidim_dummy_app"
  generate_decidim_app(
    "spec/decidim_dummy_app",
    "--app_name",
    "#{base_app_name}_test_app",
    "--path",
    "../..",
    "--skip_spring",
    "--demo",
    "--force_ssl",
    "false",
    "--locales",
    "en,fr,es"
  )
  Rake::Task["prepare_tests"].invoke
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
  File.open(config_file, "w") { |f| YAML.dump({ "development" => database_yml, "test" => database_yml }, f) }
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
