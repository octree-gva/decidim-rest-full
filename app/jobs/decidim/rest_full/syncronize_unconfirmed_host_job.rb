# frozen_string_literal: true

module Decidim
  module RestFull
    class SyncronizeUnconfirmedHostJob < ApplicationJob
      retry_on Decidim::RestFull::ApiException::NotFound, wait: 1.minute, attempts: 10
      discard_on IPAddr::InvalidAddressError
      discard_on Decidim::RestFull::ApiException::BadRequest

      def perform(organization_id)
        organization = Decidim::Organization.find(organization_id)
        Decidim::RestFull::SyncronizeUnconfirmedHost.call(organization)
      end
    end
  end
end
