# frozen_string_literal: true

module Decidim
  module RestFull
    module OrganizationClientIdsOverride
      extend ActiveSupport::Concern

      included do
        has_many :api_clients,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::RestFull::ApiClient",
                 inverse_of: :organization,
                 dependent: :destroy
      end
    end
  end
end
