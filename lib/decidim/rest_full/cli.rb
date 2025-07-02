#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "devise"
require "decidim/core"
require "decidim/rest_full"
require_relative "cli/base"
require_relative "cli/create"
require_relative "cli/get"
require_relative "cli/grant"
require_relative "cli/revoke"

module Decidim
  module RestFull
    module CLI
      class ApiClient
        def initialize
          @main_parser = OptionParser.new do |opts|
            opts.banner = <<~USAGE
              Manage Decidim's API Clients (v.#{::Decidim::RestFull.version})
              Usage: api-client [command] [options]
              Commands:
                - create: Create a new API client
                - get: Get an existing API client
                - grant: Grant a permission to an existing API client
                - revoke: Revoke a permission from an existing API client
            USAGE

            opts.on("-h", "--help", "Show this help message") do
              puts opts # rubocop:disable Rails/Output
              exit 0 # rubocop:disable Rails/Exit
            end
          end
        end

        def run(args)
          if ENV.fetch("DISABLE_REST_FULL_BIN", "false") == "true"
            Rails.logger.debug "client-api is disabled. See DISABLE_REST_FULL_BIN environment variable"
            exit 0 # rubocop:disable Rails/Exit
          end
          command = args.first

          case command
          when "create"
            Commands::Create.new.run(args[1..])
          when "get"
            Commands::Get.new.run(args[1..])
          when "grant"
            Commands::Grant.new.run(args[1..])
          when "revoke"
            Commands::Revoke.new.run(args[1..])
          when "help", nil
            puts @main_parser # rubocop:disable Rails/Output
          else
            puts @main_parser # rubocop:disable Rails/Output
            puts "Unknown command: #{command}" # rubocop:disable Rails/Output
            exit 0 # rubocop:disable Rails/Exit
          end
        end
      end
    end
  end
end

Decidim::RestFull::CLI::ApiClient.new.run(ARGV) if __FILE__ == $PROGRAM_NAME
