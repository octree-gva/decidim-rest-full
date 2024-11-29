# frozen_string_literal: true

module Decidim
  module RestFull
    # The form that validates the data to construct a valid OAuthApplication.
    class ApiPermissions < Decidim::Form
      mimic :system_api_client
      attribute :permissions, [String]
      attribute :api_client_id, Integer

      def organization
        current_organization || Decidim::Organization.find_by(id: decidim_organization_id)
      end
    end
  end
end
