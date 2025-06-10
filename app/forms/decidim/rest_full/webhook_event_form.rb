# frozen_string_literal: true

module Decidim
  module RestFull
    class WebhookEventForm < Decidim::Form
      attribute :type, String
      attribute :data, Hash
      attribute :timestamp, Integer
      validates :type, presence: true
      validates :data, presence: true
      validate :valid_organization?
      validate :valid_api_client?

      private

      def valid_organization?
        errors.add(:context, "is not valid") unless context.organization
      end

      def valid_api_client?
        errors.add(:context, "is not valid") unless context.api_client
      end

      def api_client
        @api_client ||= context.api_client
      end

      def organization
        @organization ||= context.organization
      end
    end
  end
end
