# frozen_string_literal: true

require "doorkeeper/grape/helpers"
# Require system endpoints
require_relative "organization"
module Decidim
  module RestFull
    module System
      class API < Grape::API
        helpers Doorkeeper::Grape::Helpers
        before do
          doorkeeper_authorize! :system
        end
        version "v1", using: :header, vendor: "decidim"
        format :json
        prefix "system"
        mount Organization
      end
    end
  end
end
