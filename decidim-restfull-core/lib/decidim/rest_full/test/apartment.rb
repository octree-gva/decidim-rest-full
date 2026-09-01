# frozen_string_literal: true

require "decidim/apartment/test/factories"

module Decidim
  module RestFull
    module Test
      # Create a tenant schema for each organization host (request specs).
      module ApartmentOrg
        def self.provision!(org)
          return unless api_request_example?

          ::Apartment::Tenant.switch!("public")
          existing = Decidim::Apartment::DistributionKey.for_host(org.host)
          return ::Apartment::Tenant.switch!(existing.key) if existing

          key = create_key!(org.host)
          create_schema!(key)
          ::Apartment::Tenant.switch!(key.key)
        end

        def self.api_request_example?
          RSpec.current_example&.file_path.to_s.exclude?("/rest_full/system/")
        end

        def self.create_key!(host)
          Decidim::Apartment::DistributionKey.create!(host:)
        end

        def self.create_schema!(key)
          ::Apartment::Tenant.create(key.key)
        rescue ::Apartment::TenantExists
          nil
        end
      end
    end
  end
end

FactoryBot.modify do
  factory :organization do
    before(:create) { |org| Decidim::RestFull::Test::ApartmentOrg.provision!(org) }
  end
end

RSpec.configure do |config|
  config.after do
    Apartment::Tenant.switch!("public")
  rescue StandardError
    nil
  end
end
