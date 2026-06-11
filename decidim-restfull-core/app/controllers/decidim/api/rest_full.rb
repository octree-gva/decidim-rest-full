# frozen_string_literal: true

module Decidim
  module Api
    # Decidim::Api is defined in decidim-api (lib); Zeitwerk cannot auto-vivify RestFull on eager load.
    module RestFull
    end
  end
end
