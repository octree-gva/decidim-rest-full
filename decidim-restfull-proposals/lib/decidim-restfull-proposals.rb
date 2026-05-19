# frozen_string_literal: true

require "decidim-restfull-core"

module Decidim
  module RestFull
    module Proposals
      ENGINE_ROOT = File.expand_path("..", __dir__).freeze
    end
  end
end

require "decidim/rest_full/http_cache/proposal_show_fingerprint"
require "decidim/rest_full/proposals/proposal_client_id_override"
require "decidim/rest_full/proposals/proposals_controller_override"
require "decidim/rest_full/proposals/ransackers"
require "decidim/rest_full/proposals/engine"
