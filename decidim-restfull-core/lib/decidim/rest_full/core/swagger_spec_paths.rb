# frozen_string_literal: true

require_relative "gem_spec_paths"

module Decidim
  module RestFull
    module Core
      # Extra RSpec paths for +bin/swaggerize+ (rswag). Request specs live in each +decidim-restfull-*+ gem;
      # +spec/rest_full_swagger_spec_paths.rb+ registers them (see +GemSpecPaths+).
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
            []
          end

          def env_paths
            ENV.fetch("DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS", "").split(",").map(&:strip).reject(&:empty?)
          end

          def rspec_paths
            expand_paths(default_paths + extra + env_paths)
          end

          def expand_paths(paths)
            root = GemSpecPaths.monorepo_root
            paths.flatten.compact.flat_map { |path| expand_path(path, root) }.uniq.sort
          end

          def expand_path(path, root)
            full = File.expand_path(path, root)
            if path.include?("*")
              Dir.glob(full).select { |f| File.file?(f) && f.end_with?("_spec.rb") }
            elsif File.directory?(full) || File.file?(full)
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
