# frozen_string_literal: true

module Decidim
  module RestFull
    module CLI
      module Commands
        class Delete < Base
          def run(args)
            parse_options(args)
            execute
          end

          private

          def parse_options(args)
            OptionParser.new do |opts|
              opts.banner = <<~USAGE
                Rest Full CLI for Decidim (V.#{::Decidim::RestFull.version})
                Usage: api-client delete --id CLIENT_ID
              USAGE
              default_options(opts)
              opts.on("--id ID", "Client ID (required)") { |id| @options[:id] = id }
            end.parse!(args)
          end

          def execute
            puts_error("Error: --id is required") if @options[:id].blank?

            api_client = Decidim::RestFull::Core::ApiClient.find_by(uid: @options[:id])
            puts_error("Error: client with ID #{@options[:id]} does not exist") unless api_client

            Doorkeeper::AccessToken.where(application_id: api_client.id).delete_all
            api_client.permissions.delete_all
            Decidim::RestFull::Core::WebhookRegistration.where(api_client_id: api_client.id).delete_all
            api_client.destroy!

            payload = { deleted: true, id: @options[:id] }
            if format == "json"
              puts(payload.to_json) # rubocop:disable Rails/Output
            else
              puts "deleted id=#{@options[:id]}" # rubocop:disable Rails/Output
            end
          end
        end
      end
    end
  end
end
