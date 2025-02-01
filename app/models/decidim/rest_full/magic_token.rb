# frozen_string_literal: true

module Decidim
  module RestFull
    class MagicToken < ::ApplicationRecord
      self.table_name = "decidim_rest_full_user_magic_tokens"
      belongs_to :user, class_name: "Decidim::User"

      validates :magic_token, presence: true, uniqueness: true
      validates :expires_at, presence: true

      before_validation :set_magic_token, if: -> { magic_token.blank? }
      before_validation :set_expiration, if: -> { expires_at.blank? }

      # Checks if the token is valid (not expired)
      def valid_token?
        expires_at > Time.current
      end

      # Alias mark_as_used to destroy
      alias mark_as_used destroy

      private

      def set_magic_token
        loop do
          self.magic_token = ::Base64.urlsafe_encode64(::Devise.friendly_token(20))
          break unless self.class.exists?(magic_token: magic_token)
        end
      end

      # Sets the expiration time for the token to 5minutes
      def set_expiration
        self.expires_at = 5.minutes.from_now
      end
    end
  end
end
