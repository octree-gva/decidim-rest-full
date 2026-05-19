# frozen_string_literal: true

require "decidim-restfull-core"

module Decidim
  module RestFull
    module Accountabilities
      ENGINE_ROOT = File.expand_path("..", __dir__).freeze
    end
  end
end

require "decidim/rest_full/accountabilities/engine"
