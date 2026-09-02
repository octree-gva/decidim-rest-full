# frozen_string_literal: true

module Decidim
  module RestFull
    module UpdateOrganizationFormOverride
      extend ActiveSupport::Concern

      included do
        attribute :unconfirmed_host, String

        validates :unconfirmed_host, presence: true
        validate :unique_host
        alias_method :decidim_rest_full_map_model, :map_model

        def map_model(model)
          decidim_rest_full_map_model(model)
          with_unconfirmed_host(model)
        end

        def with_unconfirmed_host(model)
          self.unconfirmed_host = extended_data(model)["unconfirmed_host"]&.to_s || model.host unless unconfirmed_host
        end

        private

        def extended_data(model)
          model.extended_data&.data || {}
        end

        def unique_host
          return unless unconfirmed_host.present? && unconfirmed_host != host
          return unless host_taken?(unconfirmed_host)

          errors.add(:unconfirmed_host, :taken)
        end

        def host_taken?(value)
          return true if Decidim::Organization.where(host: value).where.not(id:).exists?
          return false unless Gem.loaded_specs.has_key?("ros-apartment")

          Decidim::Apartment::DistributionKey.for_host(value).present?
        end
      end
    end
  end
end
