# frozen_string_literal: true

module Decidim
  module RestFull
    module CLI
      module Commands
        class Get < Base
          attr_reader :parser

          def run(args)
            parse_options(args)
            execute
          end

          private

          def parse_options(args)
            @parser = OptionParser.new do |opts|
              opts.banner = <<~USAGE
                Rest Full CLI for Decidim (V.#{::Decidim::RestFull.version})
                Usage: api-client get [options]
              USAGE

              default_options(opts)

              opts.on("--id ID", "Client ID") do |id|
                @options[:id] = id
              end
            end
            parser.parse!(args)
          end

          def execute
            matches = if @options[:id]
                        Decidim::RestFull::ApiClient.where(uid: @options[:id]).limit(1)
                      else
                        Decidim::RestFull::ApiClient.all
                      end
            if matches.any?
              if matches.size > 1
                matches.map { |match| puts_api_client match }
              else
                puts_api_client matches.first
              end
            else
              puts_error("Error: client with ID #{@options[:id]} does not exist")
            end
          end
        end
      end
    end
  end
end
