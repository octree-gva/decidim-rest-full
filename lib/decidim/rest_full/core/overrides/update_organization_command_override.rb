# frozen_string_literal: true

module Decidim
  module RestFull
    module UpdateOrganizationCommandOverride
      extend ActiveSupport::Concern

      included do
        private

        alias_method :decidim_rest_full_save_organization, :save_organization
        def save_organization
          if form.unconfirmed_host.present?
            organization.extended_data.data["unconfirmed_host"] = if form.unconfirmed_host == form.host
                                                                    nil
                                                                  else
                                                                    form.unconfirmed_host
                                                                  end
          end
          decidim_rest_full_save_organization
          organization.extended_data.save!
          Decidim::RestFull::SyncronizeUnconfirmedHostJob.perform_later(organization.id)
        end
      end
    end
  end
end
