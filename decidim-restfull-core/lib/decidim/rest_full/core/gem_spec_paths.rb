# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Monorepo gem spec directories (request specs drive OpenAPI via +bin/swaggerize+).
      module GemSpecPaths
        GEMS = %w(
          decidim-restfull-core
          decidim-restfull-proposals
          decidim-restfull-blogs
          decidim-restfull-forms
          decidim-restfull-meetings
          decidim-restfull-surveys
          decidim-restfull-budgets
          decidim-restfull-debates
          decidim-restfull-accountabilities
          decidim-restfull-sortition
        ).freeze

        class << self
          def monorepo_root
            ENV.fetch("DECIDIM_REST_FULL_ROOT") do
              File.expand_path("../../../../..", __dir__)
            end
          end

          def gem_root(gem_name)
            File.join(monorepo_root, gem_name)
          end

          def spec_dir(gem_name)
            File.join(gem_root(gem_name), "spec")
          end

          def request_spec_glob(gem_name)
            File.join(spec_dir(gem_name), "requests/**/*_spec.rb")
          end

          def request_spec_globs
            GEMS.map { |gem| request_spec_glob(gem) }
          end

          def existing_spec_dirs
            GEMS.filter_map { |gem| spec_dir(gem) if Dir.exist?(spec_dir(gem)) }
          end

          def register_swagger_paths!
            request_spec_globs.each do |glob|
              SwaggerSpecPaths.register(glob)
            end
          end
        end
      end
    end
  end
end
