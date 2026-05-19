# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Components
        class ProposalComponentsController < Decidim::Api::RestFull::Components::ComponentsController
          before_action { doorkeeper_authorize! :public }
          before_action { ability.authorize! :read, ::Decidim::Component }

          def index
            query = collection.reorder(nil).ransack(params[:filter]).result
            page = paginate(in_visible_spaces(query))
            data = page.map do |component|
              Decidim::Api::RestFull::Proposals::ProposalComponentSerializer.new(
                component,
                params: {
                  only: [],
                  locales: available_locales,
                  host: current_organization.host,
                  act_as:,
                  client_id:
                }
              ).serializable_hash[:data]
            end
            render_json_with_conditional_get({ data: }, fingerprint: collection_fingerprint_for(page))
          end

          def show
            resource_id = params.require(:id).to_i
            match = collection.find(resource_id)
            payload = Decidim::Api::RestFull::Proposals::ProposalComponentSerializer.new(
              match,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as:,
                client_id:
              }
            ).serializable_hash
            render_json_with_conditional_get(payload, fingerprint: resource_fingerprint_for(match))
          end

          protected

          def voted?
            proposal_votes.exists?
          end

          def last_vote
            proposal_votes.last
          end

          def proposal_votes
            proposal.votes.where(decidim_author_id: current_user.id)
          end

          def proposal
            @proposal ||= collection.find(params.require(:resource_id))
          end

          def proposal_component
            @proposal_component ||= proposal.component
          end

          def order_columns
            %w(rand published_at)
          end

          def default_order_column
            "published_at"
          end

          def component_manifest
            "proposals"
          end

          def model_class
            Decidim::Component
          end

          def collection
            model_class.where(manifest_name: "proposals")
          end
        end
      end
    end
  end
end
