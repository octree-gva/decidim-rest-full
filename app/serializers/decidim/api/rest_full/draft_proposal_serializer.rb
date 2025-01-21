# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class DraftProposalSerializer < ProposalSerializer
        attribute :errors do |proposal, params|
          fields = params[:fields] || []
          component = proposal.component
          participatory_space = component.participatory_space
          organization = participatory_space.organization
          form = Decidim::Proposals::ProposalForm.from_model(proposal).with_context(
            current_organization: organization,
            current_participatory_space: participatory_space,
            current_component: component
          )
          form.valid?
          fields.to_h do |key|
            key_sym = :"#{key}"
            [key_sym, form.errors.select { |err| err.attribute == key_sym }.map(&:full_message)]
          end
        end

        def self.default_meta(proposal)
          scope = proposal.component.scope || proposal.participatory_space.scope
          metas = {}
          metas[:scope] = scope.id if scope
          metas
        end

        meta do |proposal, params|
          metas = default_meta(proposal)
          metas[:publishable] = params[:publishable] if params.has_key? :publishable
          metas[:client_id] = proposal.rest_full_application.api_client.client_id if proposal.rest_full_application
          metas[:fields] = params[:fields] || []

          metas
        end
      end
    end
  end
end
