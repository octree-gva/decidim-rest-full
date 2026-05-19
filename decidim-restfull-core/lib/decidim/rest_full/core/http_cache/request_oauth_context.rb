# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      module HttpCache
        # OAuth fields for fingerprints without requiring a Bearer on the request.
        module RequestOAuthContext
          module_function

          def client_id(controller)
            doorkeeper_token(controller)&.application_id
          end

          def act_as_user(controller)
            token = doorkeeper_token(controller)
            return nil unless token&.accessible?
            return nil unless controller.respond_to?(:act_as, true)

            controller.send(:act_as)
          rescue StandardError
            nil
          end

          def doorkeeper_token(controller)
            return nil unless controller.respond_to?(:doorkeeper_token, true)

            controller.send(:doorkeeper_token)
          end
        end
      end
    end
  end
end
