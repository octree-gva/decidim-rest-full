# frozen_string_literal: true

module Decidim
  module RestFull
    class ApiClient < ::Doorkeeper::Application
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :organization, foreign_key: "decidim_organization_id", class_name: "Decidim::Organization", inverse_of: :api_clients, optional: true
      has_many :permissions, class_name: "Decidim::RestFull::Permission", dependent: :destroy

      validates :scopes, presence: true
      validate :organization_required_unless_system_scope
      before_validation :dummy_attributes

      def permission_strings
        @permission_strings ||= permissions.pluck(:permission)
      end

      def owner
        organization
      end

      def scope_str
        scopes.all.join(",")
      end

      def client_id
        uid
      end

      def client_secret
        secret
      end

      private

      def organization_required_unless_system_scope
        return if scopes.include?("system")
        return if organization.present?

        errors.add(:organization, "is required")
      end

      def dummy_attributes
        return unless organization

        self.redirect_uri = "https://#{organization.host}"
        self.organization_name = organization.name
        self.organization_url = "https://#{organization.host}"
      end
    end
  end
end
