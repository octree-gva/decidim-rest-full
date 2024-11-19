# frozen_string_literal: true

module Decidim
  module RestFull
    # The form that validates the data to construct a valid OAuthApplication.
    class ApiClientForm < Decidim::Form
      mimic :system_api_client
      attribute :name, String
      attribute :decidim_organization_id, Integer
      attribute :scopes, [String]
      validates :name, :decidim_organization_id, presence: true
      
      def organization
        current_organization || Decidim::Organization.find_by(id: decidim_organization_id)
      end
    end
  end
end
