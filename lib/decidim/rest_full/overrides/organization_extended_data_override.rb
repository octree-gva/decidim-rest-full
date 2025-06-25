# frozen_string_literal: true

module Decidim
  module RestFull
    module OrganizationExtendedDataOverride
      extend ActiveSupport::Concern

      included do
        has_one :extended_data,
                foreign_key: "organization_id",
                class_name: "Decidim::RestFull::OrganizationExtendedData",
                inverse_of: :organization

        after_create :ensure_organization_extended_data
      end

      private

      def ensure_organization_extended_data
        create_extended_data
      end
    end
  end
end
