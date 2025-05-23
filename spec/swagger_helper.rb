# frozen_string_literal: true

require "spec_helper"
require "rswag/specs"

require "swagger_openapi_specs"
require "swagger_shared_examples"
# spec/swagger_helper.rb

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s
  config.extend Decidim::RestFull::Test::OnApiEndpointMethods
  config.before do
    I18n.available_locales = Decidim.available_locales = %w(en fr es)
    I18n.default_locale = Decidim.default_locale = :en

    Decidim::RestFull::Test::GlobalContext.security_type = nil
  end

  # On example, will save the test result and insert it as
  # an example in the swagger file.
  config.after do |example|
    next unless example.metadata[:type] == :request

    content = example.metadata[:response][:content] || {}
    example_name = example.metadata[:example_name]
    if example_name
      response && response.body ? response.body : "{}"
      json_data = begin
        JSON.parse(response.body, symbolize_names: true)
      rescue StandardError
        {}
      end
      example_spec = {
        "application/json" => {
          examples: {
            example_name.to_sym => {
              value: json_data
            }
          }
        }
      }
      example.metadata[:response][:content] = content.deep_merge(example_spec)
    end
  end

  # Add the openapi specs to the config
  config.openapi_specs = Decidim::RestFull::Test.openapi_specs
end
