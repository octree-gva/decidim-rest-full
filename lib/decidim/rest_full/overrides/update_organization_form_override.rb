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
          self.unconfirmed_host = model.extended_data.data["unconfirmed_host"] || model.host unless unconfirmed_host
        end

        private

        def unique_host
          if unconfirmed_host.present? && unconfirmed_host != host && Decidim::Organization.where(host: unconfirmed_host).where.not(id: id).exists?
            errors.add(:unconfirmed_host, :taken)
          end
        end
      end
    end
  end
end
