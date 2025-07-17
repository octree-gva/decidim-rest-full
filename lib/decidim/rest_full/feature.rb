# frozen_string_literal: true

module Decidim
  module RestFull
    ##
    # Singleton feature toggle, to control:
    # - registrable scopes
    # - exposed endpoints
    class Feature
      include Singleton

      def blog?
        available_scopes.include?("blogs")
      end

      def proposal?
        available_scopes.include?("proposals")
      end

      def system?
        available_scopes.include?("system")
      end

      def public?
        available_scopes.include?("public")
      end

      def health?
        Decidim::RestFull.config.health_enabled
      end

      def magic_link?
        Decidim::RestFull.config.magic_link_enabled
      end
      
      def available_scopes
        @available_scopes ||= Decidim::RestFull.config.available_permissions.keys
      end

      def available_permissions
        @available_permissions ||= Decidim::RestFull.config.available_permissions.values.flatten
      end
    end
  end
end
