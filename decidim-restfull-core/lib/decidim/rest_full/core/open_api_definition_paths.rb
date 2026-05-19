# frozen_string_literal: true

require_relative "gem_spec_paths"

module Decidim
  module RestFull
    module Core
      # OpenAPI schema definition files (+DefinitionRegistry+ registrations) contributed by feature gems.
      # Register from +Extension.register+ via +ext.open_api_definitions+ (same pattern as +ext.rswag_specs+).
      module OpenApiDefinitionPaths
        class << self
          def register(*path_or_globs)
            extra.concat(path_or_globs.flatten.compact)
          end

          def extra
            @extra ||= []
          end

          def reset!
            @extra = []
            @loaded = false
          end

          def env_paths
            ENV.fetch("DECIDIM_REST_FULL_OPENAPI_DEFINITION_PATHS", "").split(",").map(&:strip).reject(&:empty?)
          end

          def loaded?
            @loaded == true
          end

          def load_all!
            return if @loaded

            @loaded = true
            expand_paths(extra + env_paths).each { |file| require file }
          end

          def expand_paths(paths)
            root = GemSpecPaths.monorepo_root
            paths.flatten.compact.flat_map { |path| expand_path(path, root) }.uniq.sort
          end

          def expand_path(path, root)
            full = File.expand_path(path, root)
            if path.include?("*")
              Dir.glob(full).select { |f| File.file?(f) && f.end_with?(".rb") }
            elsif File.file?(full)
              [full]
            else
              []
            end
          end
        end
      end
    end
  end
end
