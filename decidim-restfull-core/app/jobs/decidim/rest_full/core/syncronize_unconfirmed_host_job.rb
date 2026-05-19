# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class SyncronizeUnconfirmedHostJob < ::Decidim::RestFull::ApplicationJob
        retry_on Decidim::RestFull::Core::ApiException::NotFound, wait: 1.minute, attempts: 10
        discard_on IPAddr::InvalidAddressError
        discard_on Decidim::RestFull::Core::ApiException::BadRequest

        def perform(organization_id)
          organization = Decidim::Organization.find(organization_id)
          Decidim::RestFull::Core::SyncronizeUnconfirmedHost.call(organization)
        end
      end
    end
  end
end
