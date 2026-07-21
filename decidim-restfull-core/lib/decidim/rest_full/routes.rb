# frozen_string_literal: true

module Decidim
  module RestFull
    # Public API for drawing RestFull routes on Decidim::Core::Engine.routes.
    # Call {ensure_routes!} at boot and other critical points (menu render, to_prepare).
    module Routes
      class << self
        # Idempotent: draw API + system routes and repair Warden :admin strategies.
        def ensure_routes!(routes = Decidim::Core::Engine.routes)
          ensure_restfull_routes!(routes)
          ensure_warden_admin_strategies!
        end

        def ensure_restfull_routes!(routes = Decidim::Core::Engine.routes)
          draw!(routes)
        end

        def draw!(routes = Decidim::Core::Engine.routes)
          ensure_core_routes_block_loaded!
          return if routes_drawn?(routes)

          Core::RouteRegistry.apply!(routes)
          # NamedRouteCollection#clear! replaces helper modules; drop memoized proxies
          # so callers see helpers defined after a late draw.
          routes.instance_variable_set(:@url_helpers_with_paths, nil)
          routes.instance_variable_set(:@url_helpers_without_paths, nil)
        end

        def applied?
          routes_drawn?
        end

        def routes_drawn?(routes = Decidim::Core::Engine.routes)
          routes.routes.any? { |r| r.path.spec.to_s.include?("/api/rest_full/v") }
        end

        # Devise locks Warden on the first RouteSet#finalize!. Core can win that race
        # before System registers :admin, leaving empty admin strategies (login 401).
        def ensure_warden_admin_strategies!
          return unless defined?(::Devise)
          return unless ::Devise.mappings[:admin]
          return if ::Devise.warden_config&.default_strategies(scope: :admin)&.include?(:database_authenticatable)

          # rubocop:disable Style/ClassVars -- Devise has no public API to re-run configure_warden!
          ::Devise.class_variable_set(:@@warden_configured, nil)
          # rubocop:enable Style/ClassVars
          ::Devise.configure_warden!
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
