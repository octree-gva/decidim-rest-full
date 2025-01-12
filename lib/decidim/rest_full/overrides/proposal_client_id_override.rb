# frozen_string_literal: true

module Decidim
  module RestFull
    module ProposalClientIdOverride
      extend ActiveSupport::Concern

      included do
        has_one :rest_full_application,
                foreign_key: "proposal_id",
                class_name: "Decidim::RestFull::ProposalApplicationId",
                dependent: :destroy
      end
    end
  end
end
