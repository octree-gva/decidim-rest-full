# frozen_string_literal: true

module Decidim
  module RestFull
    module Test
      # Optional Swagger/OpenAPI +tags+ entries contributed by +decidim-restfull-*+ gems when their
      # +test_definitions+ load (mirrors the registry pattern used in +Decidim.component_registry+).
      module OpenApiTagRegistry
        class << self
          def register_tag(tag_hash)
            tag_definitions.append(tag_hash)
          end

          def tag_definitions
            @tag_definitions ||= []
          end

          def clear!
            @tag_definitions = []
          end
        end
      end
    end
  end
end
