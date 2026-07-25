# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Gates Doorkeeper token endpoints when RestFull master Toggle is off.
      module TokensAvailability
        extend ActiveSupport::Concern

        included do
          before_action :ensure_rest_full_enabled_for_tokens!
        end

        private

        def ensure_rest_full_enabled_for_tokens!
          organization = request.env["decidim.current_organization"]
          Decidim::RestFull::Core::ModuleAvailability.ensure_available!(organization)
        end
      end
    end
  end
end
