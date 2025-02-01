# frozen_string_literal: true

module Decidim
  module RestFull
    module UserMagicTokenOverride
      extend ActiveSupport::Concern

      included do
        # Association
        has_one :rest_full_magic_token,
                foreign_key: "user_id",
                class_name: "Decidim::RestFull::MagicToken",
                dependent: :destroy

        # Generates a new magic token for the user
        def rest_full_generate_magic_token
          # Destroy any existing magic token
          rest_full_magic_token&.destroy

          # Create a new magic token
          create_rest_full_magic_token!
        end
      end
    end
  end
end
