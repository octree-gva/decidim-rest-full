# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      class ProposalApplicationId < ::ApplicationRecord
        self.table_name = "proposal_application_ids"

        belongs_to :api_client, class_name: "Decidim::RestFull::Core::ApiClient"
        belongs_to :proposal, class_name: "Decidim::Proposals::Proposal"
      end
    end
  end
end
