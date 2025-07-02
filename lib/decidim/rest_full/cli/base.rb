# frozen_string_literal: true

module Decidim
  module RestFull
    module CLI
      module Commands
        class Base
          def initialize
            @options = {
              format: "json",
              id: nil
            }
          end

          def format
            @options[:format]
          end

          protected

          def validate_permissions(permissions, scopes)
            permission_mapping = ::Decidim::RestFull.config.available_permissions
            permission_without_validation = ["oauth.impersonate", "oauth.login"]

            allowed_permissions = scopes.map do |scope|
              permission_mapping[scope.to_s]
            end.flatten.uniq

            permissions.each do |permission|
              unless permission_without_validation.include?(permission) || allowed_permissions.include?(permission)
                puts_error("Error: can not grant permission #{permission} to client #{api_client.uid}, wrong scope")
              end
            end
          end

          def default_options(opts)
            opts.on("--format FORMAT", "Output format. `json` or `text`") do |format|
              @options[:format] = format
            end

            opts.on("-h", "--help", "Show command help") do
              puts opts # rubocop:disable Rails/Output
              exit 0 # rubocop:disable Rails/Exit
            end
          end

          def red(text)
            "\e[31m#{text}\e[0m"
          end

          def puts_error(text)
            if format == "json"
              puts({ error: text }.to_json) # rubocop:disable Rails/Output
            else
              puts "" # rubocop:disable Rails/Output
              puts red(text) # rubocop:disable Rails/Output
            end
            exit 0 # rubocop:disable Rails/Exit
          end

          def puts_api_client(api_client)
            payload = {
              id: api_client.uid,
              secret: api_client.secret,
              name: api_client.name,
              scopes: api_client.scopes,
              permissions: api_client.permissions.pluck(:permission),
              organization_id: api_client.decidim_organization_id
            }
            if format == "json"
              puts(payload.to_json) # rubocop:disable Rails/Output
            else
              puts "" # rubocop:disable Rails/Output
              payload.each do |key, value|
                puts "#{key}=#{value}"
              end
            end
          end
        end
      end
    end
  end
end
