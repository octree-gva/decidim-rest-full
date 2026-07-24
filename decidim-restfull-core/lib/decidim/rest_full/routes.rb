# frozen_string_literal: true

module Decidim
  module RestFull
    # Draws RestFull routes on Decidim::Core::Engine.routes.
    #
    # Boot: {mount!} queues via RouteSet#append (same as Admin/System).
    # RoutesReloader finalize!s once — leave Devise alone.
    module Routes
      class << self
        def mount!
          return if @mounted

          ensure_core_routes_block_loaded!
          @mounted = true
          Decidim::Core::Engine.routes do
            Core::RouteRegistry.draw_routes_on(self)
          end
        end

        # Immediate draw without finalize! (specs / late registration fallback).
        def draw!(routes = Decidim::Core::Engine.routes)
          ensure_core_routes_block_loaded!
          return if routes_drawn?(routes)

          Core::RouteRegistry.apply!(routes)
          routes.instance_variable_set(:@url_helpers_with_paths, nil)
          routes.instance_variable_set(:@url_helpers_without_paths, nil)
        end

        def applied?
          routes_drawn?
        end

        def routes_drawn?(routes = Decidim::Core::Engine.routes)
          routes.routes.any? { |r| r.path.spec.to_s.include?("/api/rest_full/v") }
        end

        def draw_api_routes(&)
          Core::RouteRegistry.draw_api_routes(&)
        end

        def append_pending!(routes = Decidim::Core::Engine.routes)
          Core::RouteRegistry.append_pending!(routes)
        end

        private

        def ensure_core_routes_block_loaded!
          return if Core::RouteRegistry.core_routes_defined?

          routes_file = Core::Engine.root.join("config/routes.rb")
          load routes_file.to_s if routes_file.exist?
        end
      end
    end
  end
end
