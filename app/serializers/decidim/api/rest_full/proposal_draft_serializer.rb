# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ProposalDraftSerializer < ProposalSerializer
        attribute :errors do |proposal, _params|
          component = proposal.component
          participatory_space = component.participatory_space
          organization = participatory_space.organization
          form = Decidim::Proposals::ProposalForm.from_model(proposal).with_context(
            current_organization: organization,
            current_participatory_space: participatory_space,
            current_component: component
          )
          form.valid?
          {
            title: form.errors.select { |err| err.attribute == :title }.map(&:full_message),
            body: form.errors.select { |err| err.attribute == :body }.map(&:full_message)
          }
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

          metas
        end
      end
    end
  end
end
