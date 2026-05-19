# frozen_string_literal: true

require "decidim-restfull-core"

module Decidim
  module RestFull
    module Budgets
      ENGINE_ROOT = File.expand_path("..", __dir__).freeze
    end
  end
end

require "decidim/rest_full/budgets/engine"
