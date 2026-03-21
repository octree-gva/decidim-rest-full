# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Extra RSpec paths for +bin/swaggerize+ (rswag). Core always includes +spec/requests/+.
      # Extensions that register routes and +DefinitionRegistry+ entries should also register
      # their request spec globs so one swaggerize run merges paths into the OpenAPI document.
      #
      # Call from an engine initializer (host app loads all engines) or from
      # +spec/rest_full_swagger_spec_paths.rb+ (loaded by +bin/swaggerize+ before RSpec).
      # Comma-separated globs in ENV +DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS+ are merged too.
      module SwaggerSpecPaths
        class << self
          def register(*path_or_globs)
            extra.concat(path_or_globs.flatten.compact)
          end

          def extra
            @extra ||= []
          end

          def reset!
            @extra = []
          end

          def default_paths
            ["spec/requests"]
          end

          def env_paths
            ENV.fetch("DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS", "").split(",").map(&:strip).reject(&:empty?)
          end

          def rspec_paths
            (default_paths + extra + env_paths).flatten.compact.uniq
          end
        end
      end
    end
  end
end
