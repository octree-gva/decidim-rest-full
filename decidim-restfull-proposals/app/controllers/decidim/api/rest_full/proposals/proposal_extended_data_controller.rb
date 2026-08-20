# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposals
        class ProposalExtendedDataController < Decidim::Api::RestFull::Core::ResourcesController
          include Decidim::Api::RestFull::ExtendedDataEndpoints

          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :read, ::Decidim::Proposals::Proposal }

          private

          def extended_data_resource
            @extended_data_resource ||= begin
              proposal = filter_for_context(Decidim::Proposals::Proposal).find_by(id: params.require(:id))
              raise Decidim::RestFull::Core::ApiException::NotFound, "Proposal not found" unless proposal

              proposal
            end
          end

          def extended_data_subject_class
            ::Decidim::Proposals::Proposal
          end
        end
      end
    end
  end
end
