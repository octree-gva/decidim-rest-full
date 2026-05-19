# frozen_string_literal: true

module Decidim
  module RestFull
    # Replays OAuth + tenant context for async jobs (no raw bearer string stored).
    class ApiExecutionContext
      attr_reader :organization, :doorkeeper_token

      def initialize(organization:, doorkeeper_token:)
        @organization = organization
        @doorkeeper_token = doorkeeper_token
      end

      def self.from_controller(controller)
        new(
          organization: controller.send(:current_organization),
          doorkeeper_token: controller.send(:doorkeeper_token)
        )
      end

      def current_user
        @current_user ||= Decidim::User.find_by(id: doorkeeper_token.resource_owner_id, organization:)
      end

      def service_token?
        doorkeeper_token.valid? && !doorkeeper_token.resource_owner_id
      end

      def act_as
        @act_as ||= if service_token?
                      Decidim::User.where(admin: true, blocked_at: nil, organization:).where.not(confirmed_at: nil).first
                    elsif current_user
                      current_user
                    end
      end

      def client_id
        doorkeeper_token.application_id
      end

      def ability
        Decidim::RestFull::Core::Ability.from_doorkeeper_token(doorkeeper_token)
      end

      def current_locale
        @current_locale ||= if current_user
                              current_user.locale || organization.default_locale
                            else
                              organization.default_locale
                            end
      end

      def available_locales
        @available_locales ||= I18n.available_locales.map(&:to_sym)
      end
    end
  end
end
