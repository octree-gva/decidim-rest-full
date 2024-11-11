# frozen_string_literal: true

require "doorkeeper/grape/helpers"
# Require spaces endpoints
require_relative "space"
module Decidim
  module RestFull
    module Spaces
      class API < Grape::API
        helpers Doorkeeper::Grape::Helpers
        before do
          doorkeeper_authorize! :spaces
        end
        version "v1", using: :header, vendor: "decidim"
        format :json
        prefix "spaces"
        mount Space
      end
    end
  end
end
