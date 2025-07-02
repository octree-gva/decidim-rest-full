# frozen_string_literal: true

module Decidim
  module RestFull
    module CLI
      module Commands
        class Create < Base
          def initialize
            super
            @options[:id] ||= "id_#{::Devise.friendly_token(16)}"
            @options[:secret] ||= "key_#{::Devise.friendly_token(32)}"
            @options[:name] ||= "API Client ***#{@options[:id][-4..]}"
            @options[:decidim_organization_id] ||= nil
            @options[:allow_impersonate] ||= false
            @options[:allow_login] ||= false
          end

          def run(args)
            parse_options(args)
            execute
          end

          private

          def parse_options(args)
            parser = OptionParser.new do |opts|
              opts.banner = <<~USAGE
                Manage Decidim's API Clients (v.#{::Decidim::RestFull.version})
                Usage: api-client create [options]
              USAGE
              default_options(opts)

              opts.on("--scope SCOPE", "API scope") do |scope|
                @options[:scopes] ||= []
                @options[:scopes] << scope unless @options[:scopes].include?(scope)
              end
              opts.on("--perm PERMISSION", "--permission PERMISSION", "Permission") do |permission|
                @options[:permissions] ||= []
                @options[:permissions] << permission unless @options[:permissions].include?(permission)
              end
              opts.on("--name NAME", "Client name") do |name|
                @options[:name] = name
              end

              opts.on("--id ID", "Client ID") do |id|
                @options[:id] = id
              end

              opts.on("--organization-id ORGANIZATION_ID", "Organization ID") do |organization_id|
                @options[:decidim_organization_id] = organization_id
              end

              opts.on("--secret SECRET", "Client secret") do |secret|
                @options[:secret] = secret
              end

              opts.on("--allow-impersonate", "If client can impersonate a user") do
                @options[:allow_impersonate] = true
              end

              opts.on("--allow-login", "If client can insert user/password to login") do
                @options[:allow_login] = true
              end
            end
            parser.parse!(args)
          end

          def before_execute!
            puts_error("Error: at least one --scope is required") unless @options[:scopes]
            if @options[:id] && Decidim::RestFull::ApiClient.exists?(uid: @options[:id])
              # Check uniq id
              puts_error("Error: client with ID #{@options[:id]} already exists")
            end
            has_system_scope = @options[:scopes].include?("system")
            only_system_scope = @options[:scopes].size == 1 && has_system_scope
            puts_error("Error: --organization-id is required for non-system clients") if !only_system_scope && @options[:decidim_organization_id].blank?
            if @options[:decidim_organization_id] && !::Decidim::Organization.exists?(id: @options[:decidim_organization_id])
              puts_error("Error: organization with ID #{@options[:decidim_organization_id]} does not exist")
            end
          end

          def execute
            before_execute!
            permissions = @options[:permissions] || []
            permissions << "oauth.impersonate" if @options[:allow_impersonate]
            permissions << "oauth.login" if @options[:allow_login]

            api_client = Decidim::RestFull::ApiClient.new(
              scopes: @options[:scopes].uniq,
              name: @options[:name],
              uid: @options[:id],
              secret: @options[:secret],
              redirect_uri: "https://#{Decidim::Organization.first.host}"
            )
            if @options[:decidim_organization_id]
              api_client.organization = Decidim::Organization.find(@options[:decidim_organization_id])
            else
              api_client.organization_name = @options[:name]
              api_client.organization_url = "https://example.org"
            end
            validate_permissions(permissions, @options[:scopes])
            api_client.permissions = permissions.map { |permission| api_client.permissions.build(permission: permission) }
            api_client.save!
            puts_api_client api_client
          end
        end
      end
    end
  end
end
