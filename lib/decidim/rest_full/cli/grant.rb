# frozen_string_literal: true

module Decidim
  module RestFull
    module CLI
      module Commands
        ## Add a permission to an API client
        class Grant < Base
          attr_reader :parser

          def run(args)
            parse_options(args)
            execute
          end

          def parse_options(args)
            @parser = OptionParser.new do |opts|
              opts.banner = <<~USAGE
                Rest Full CLI for Decidim (V.#{::Decidim::RestFull.version})
                Usage: api-client grant [options]
              USAGE

              default_options(opts)

              opts.on("--id ID", "Client ID") do |id|
                @options[:id] = id
              end

              opts.on("--perm PERMISSION", "--permission PERMISSION", "Permission") do |permission|
                @options[:permissions] ||= []
                @options[:permissions] << permission unless @options[:permissions].include?(permission)
              end
            end
            parser.parse!(args)
          end

          def execute
            puts_error("Error: --id is required for grant command") unless @options[:id]

            api_client = Decidim::RestFull::ApiClient.find_by(uid: @options[:id])
            permissions = @options[:permissions]
            # Check if permission are valid for granted scopes

            validate_permissions(permissions, api_client.scopes)
            new_permissions = permissions.select do |permission|
              api_client.permissions.where(permission: permission).empty?
            end
            api_client.permissions << new_permissions.map do |permission|
              api_client.permissions.build(permission: permission)
            end
            api_client.save!
            puts_api_client api_client
          end
        end
      end
    end
  end
end
