# frozen_string_literal: true

module Decidim
  module RestFull
    module Test
      module_function

      def repo_root
        ENV.fetch("DECIDIM_REST_FULL_ROOT") do
          File.expand_path("../../..", __dir__)
        end
      end
    end
  end
end
