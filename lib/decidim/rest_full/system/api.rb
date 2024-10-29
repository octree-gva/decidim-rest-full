# frozen_string_literal: true

require_relative "organization"
module Decidim
  module RestFull
    module System
      class API < Grape::API
        version "v1", using: :header, vendor: "decidim"
        format :json
        prefix "system"
        mount Organization
      end
    end
  end
end
