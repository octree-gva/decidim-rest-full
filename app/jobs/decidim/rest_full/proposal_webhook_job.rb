# frozen_string_literal: true

module Decidim
  module RestFull
    class ProposalWebhookJob < ApplicationJob
      def perform(event_name, proposal_id, organization_id)
        proposal = load_proposal(proposal_id)
        organization = load_organization(organization_id)
        data = serialize_proposal(proposal, organization)
        permissions_for(event_name, organization).each do |permission|
          dispatch_for_permission(permission, event_name, data, organization)
        end
      end

      private

      def load_proposal(proposal_id)
        Decidim::Proposals::Proposal.find(proposal_id)
      end

      def load_organization(organization_id)
        Decidim::Organization.find(organization_id)
      end

      def serialize_proposal(proposal, organization)
        params = serializer_params(proposal, organization)
        return draft_serializer(proposal, params).serializable_hash if proposal.draft?

        proposal_serializer(proposal, params).serializable_hash
      end

      def serializer_params(proposal, organization)
        {
          only: [],
          locales: serializer_locales(organization),
          host: organization.host,
          publishable: publishable?(proposal, organization),
          act_as: nil
        }
      end

      def serializer_locales(organization)
        organization.available_locales || Decidim.available_locales
      end

      def publishable?(proposal, organization)
        return false unless proposal.draft?

        proposal_form_for(proposal, organization).valid?
      end

      def proposal_form_for(proposal, organization)
        Decidim::Proposals::ProposalForm
          .from_model(proposal)
          .with_context(current_organization: organization, current_component: proposal.component)
      end

      def draft_serializer(proposal, params)
        ::Decidim::Api::RestFull::DraftProposalSerializer.new(proposal, params:)
      end

      def proposal_serializer(proposal, params)
        ::Decidim::Api::RestFull::ProposalSerializer.new(proposal, params:)
      end

      def permissions_for(event_name, organization)
        Decidim::RestFull::Permission.where(permission: event_name, api_client: organization.api_clients)
      end

      def dispatch_for_permission(permission, event_name, data, organization)
        payload = build_payload(permission.api_client, event_name, data, organization)
        return log_invalid_event(event_name, payload) unless payload.valid?

        webhook_registrations_for(permission.api_client, event_name).each do |registration|
          enqueue_webhook(registration, payload)
        end
      end

      def build_payload(api_client, event_name, data, organization)
        WebhookEventForm.new(
          type: event_name,
          data:,
          timestamp: current_timestamp
        ).with_context(organization:, api_client:)
      end

      def log_invalid_event(event_name, payload)
        Rails.logger.warn("Invalid event name: #{event_name}. #{payload.errors.full_messages.join(", ")}")
      end

      def webhook_registrations_for(api_client, event_name)
        Decidim::RestFull::WebhookRegistration.where(api_client_id: api_client.id).where(
          "subscriptions @> ?", [event_name].to_json
        )
      end

      def enqueue_webhook(webhook_registration, payload)
        WebhookJob.perform_later(webhook_registration, payload.as_json, current_timestamp)
      end

      def current_timestamp
        Time.current.to_i.to_s
      end
    end
  end
end
