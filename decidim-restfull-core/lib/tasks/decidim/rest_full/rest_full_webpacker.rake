# frozen_string_literal: true

require "decidim/gem_manager"

namespace :decidim_rest_full do
  namespace :webpacker do
    desc "Installs RestFull webpacker files in Rails instance application"
    task install: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_rest_full_npm
    end

    desc "Adds RestFull dependencies in package.json"
    task upgrade: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_rest_full_npm
    end

    def install_rest_full_npm
      raise "decidim-rest_full gem is not loaded (check Gem.loaded_specs['decidim-rest_full'])" if rest_full_path.nil?

      return if rest_full_npm_dependencies.empty?

      puts "install NPM packages. You can also do this manually with this command:"
      puts "npm i #{rest_full_npm_dependencies.join(" ")}"
      rest_full_system! "npm i #{rest_full_npm_dependencies.join(" ")}"
    end

    def rest_full_npm_dependencies
      @rest_full_npm_dependencies ||= begin
        package_json = JSON.parse(File.read(rest_full_path.join("package.json")))

        (package_json["dependencies"] || {}).map { |package, version| "#{package}@#{version}" }
      end
    end

    def rest_full_path
      @rest_full_path ||= begin
        spec = rest_full_gemspec
        Pathname.new(spec.full_gem_path) if spec
      end
    end

    def rest_full_gemspec
      Gem.loaded_specs[rest_full_gem_name]
    end

    def rails_app_path
      @rails_app_path ||= Rails.root
    end

    def rest_full_system!(command)
      system("cd #{rails_app_path} && #{command}") || abort("\n== Command #{command} failed ==")
    end

    def rest_full_gem_name
      "decidim-rest_full"
    end
  end
end
