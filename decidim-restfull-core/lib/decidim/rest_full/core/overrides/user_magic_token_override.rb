# frozen_string_literal: true

module Decidim
  module RestFull
    module UserMagicTokenOverride
      extend ActiveSupport::Concern

      included do
        # Association
        has_one :rest_full_magic_token,
                foreign_key: "user_id",
                class_name: "Decidim::RestFull::Core::MagicToken",
                dependent: :destroy

        # Generates a new magic token for the user.
        # @param redirect_url [String, nil] optional HTTPS URL validated against the organization allowlist
        def rest_full_generate_magic_token(redirect_url: nil)
          rest_full_magic_token&.destroy

          attrs = {}
          attrs[:redirect_url] = redirect_url if redirect_url.present?
          create_rest_full_magic_token!(**attrs)
        end
      end
    end
  end
end
