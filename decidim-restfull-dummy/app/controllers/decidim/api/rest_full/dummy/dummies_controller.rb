# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Dummy
        # Stub resource: always 501 once Toggle allows the :dummy feature through.
        class DummiesController < Decidim::Api::RestFull::ApplicationController
          before_action { doorkeeper_authorize! :dummy }

          def index
            raise Decidim::RestFull::Core::ApiException::NotImplemented, "dummy endpoint is not implemented"
          end

          def show
            raise Decidim::RestFull::Core::ApiException::NotImplemented, "dummy endpoint is not implemented"
          end
        end
      end
    end
  end
end
