# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposals
        # Webhook envelope for any proposal lifecycle event (draft or published — same model).
        class ProposalWebhookSerializer < ::Decidim::Api::RestFull::Core::WebhookSerializer
          def self.find_example_resource(organization, event_name:)
            proposals = proposals_for(organization)
            if event_name.to_s.start_with?("draft_")
              proposals.find(&:draft?)
            else
              proposals.reverse_each.find { |proposal| !proposal.draft? }
            end
          end

          def self.proposals_for(organization)
            component_ids = Decidim::Component
                            .where(manifest_name: "proposals")
                            .filter_map do |component|
                              next unless component.organization == organization

                              component.id
                            end
            Decidim::Proposals::Proposal.where(decidim_component_id: component_ids).order(:id).to_a
          end

          protected

          def resource_serializable_hash
            params = serializer_params(publishable: publishable?)
            if resource.draft?
              DraftProposalSerializer.new(resource, params:).serializable_hash
            else
              ProposalSerializer.new(resource, params:).serializable_hash
            end
          end

          private

          def publishable?
            return false unless resource.draft?

            Decidim::Proposals::ProposalForm
              .from_model(resource)
              .with_context(current_organization: organization, current_component: resource.component)
              .valid?
          end
        end
      end
    end
  end
end
