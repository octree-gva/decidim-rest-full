# frozen_string_literal: true

module Decidim
  module RestFull
    class ProposalWebhookJob < ApplicationJob
      def perform(event_name, proposal_id, organization_id)
        proposal = Decidim::Proposals::Proposal.find(proposal_id)
        organization = Decidim::Organization.find(organization_id)
        # Form to know if the proposal is publishable
        proposal_form = Decidim::Proposals::ProposalForm.from_model(proposal).with_context(
          current_organization: organization,
          current_component: proposal.component
        )

        serializer_params = {
          only: [],
          locales: organization.available_locales || Decidim.available_locales,
          host: organization.host,
          publishable: proposal.draft? && proposal_form.valid?,
          act_as: nil
        }
        data = if proposal.draft?
                 ::Decidim::Api::RestFull::DraftProposalSerializer.new(proposal, params: serializer_params).serializable_hash
               else
                 ::Decidim::Api::RestFull::ProposalSerializer.new(proposal, params: serializer_params).serializable_hash
               end

        permissions = Decidim::RestFull::Permission.where(permission: event_name, api_client: organization.api_clients)

        permissions.each do |permission|
          api_client = permission.api_client
          payload = WebhookEventForm.new(
            type: event_name,
            data: data,
            timestamp: Time.current.to_i.to_s
          ).with_context(organization: organization, api_client: api_client)
          next Rails.logger.warn("Invalid event name: #{event_name}. #{payload.errors.full_messages.join(", ")}") unless payload.valid?

          webhook_registrations = Decidim::RestFull::WebhookRegistration.where(api_client_id: api_client.id).where(
            "subscriptions @> ?", [event_name].to_json
          )
          # For each webhook registration, send the webhook in a new job
          webhook_registrations.each do |webhook_registration|
            WebhookJob.perform_later(webhook_registration, payload.as_json, Time.current.to_i.to_s)
          end
        end
      end
    end
  end
end
