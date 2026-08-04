# frozen_string_literal: true

module Decidim
  module RestFull
    # Public registration API for decidim-restfull-* feature gems and external extensions.
    #
    #   Decidim::RestFull::Extension.register(:my_module) do |ext|
    #     ext.toggle_feature gem: "decidim-restfull-widgets"
    #     ext.controller_paths "widgets"
    #     ext.oauth_scopes :widgets
    #     ext.permissions(:widgets, "widgets.read", group: :widgets)
    #     ext.routes { resources :widgets, ... }
    #     ext.api_job "widgets#create", ->(ctx, p) { ... }
    #     ext.webhook_event "widgets.created.succeeded", scope: :widgets, payload_schema_ref: :widget,
    #                       schema_key: :wh_widget_created,
    #                       example: ->(org) { WidgetWebhookSerializer.example_envelope(org, event_name: "widgets.created.succeeded") }
    #     ext.webhooks(/decidim\.widgets\./, handler: Widgets::WebhookHandler.method(:call))
    #     ext.rswag_specs "spec/requests/**/widgets/**/*_spec.rb"
    #     ext.open_api_definitions File.join(Widgets::ENGINE_ROOT, "lib/decidim/rest_full/widgets/test_definitions.rb")
    #     ext.rest_enhancement(serializer: "Decidim::Api::RestFull::Proposals::ProposalSerializer", http_cache_profile: :proposal_show) do |e|
    #       e.has_many :widgets, serializer: WidgetSerializer do |proposal, _params|
    #         proposal.widgets
    #       end
    #       e.http_cache { |h| h.cache_time { |proposal| proposal.widgets.maximum(:updated_at) } }
    #     end
    class Extension
      class << self
        def register(name, &)
          extension = new(name)
          extension.instance_eval(&)
          extension.apply!
          extension
        end

        def doorkeeper_optional_scopes
          @doorkeeper_optional_scopes ||= []
        end

        def reset!
          @doorkeeper_optional_scopes = []
          Core::SerializerAdditionsRegistry.reset!
          Core::HttpCache::FingerprintContributorRegistry.reset!
        end
      end

      def initialize(name)
        @name = name.to_sym
        @rest_enhancement_registrations = []
        @webhook_events = []
        @controller_paths = []
      end

      # Registers optional OAuth token scopes advertised to Doorkeeper and checked via +doorkeeper_authorize!+
      # on controllers. +doorkeeper_scopes+ remains an alias for backward compatibility with older gems.
      def oauth_scopes(*scopes)
        @oauth_scopes = scopes.map(&:to_sym)
      end

      alias doorkeeper_scopes oauth_scopes

      def permissions(scope, permission, group:)
        @permissions ||= []
        @permissions << { scope: scope.to_sym, permission:, group: group.to_sym }
      end

      def routes(&block)
        @routes_block = block
      end

      def api_job(command_key, callable = nil, &block)
        handler = callable || block
        ApiJobCommandRunner.register(command_key, handler)
      end

      # Paths to RSwag request specs scanned for OpenAPI generation (+bin/swaggerize+).
      # +swagger_specs+ remains an alias for backward compatibility with older gems.
      def rswag_specs(*globs)
        @rswag_specs = globs.flatten
      end

      alias swagger_specs rswag_specs

      # Barrel (+test_definitions.rb+) or glob of +test/definitions/**/*.rb+ for +DefinitionRegistry+.
      def open_api_definitions(*paths)
        @open_api_definitions = paths.flatten
      end

      alias test_definitions open_api_definitions

      # Registers this extension as a decidim-toggle feature (+#{feature}_enabled+).
      # +feature:+ defaults to the Extension.register name. +gem:+ is checked via
      # +Decidim::Toggle.gem_present?+ (+nil+ = always present, e.g. core-shipped).
      def toggle_feature(feature = nil, gem: nil)
        @toggle_feature_name = (feature || @name).to_sym
        @toggle_feature_gem = gem
      end

      # Maps +controller_path+ URL segments to this toggle feature (see
      # +ModuleAvailability.feature_for_controller+). Prefer short last segments
      # (e.g. +"widgets"+ for +…/widgets_controller+).
      def controller_paths(*segments)
        @controller_paths = segments.flatten.map(&:to_s)
      end

      # Subscribe to ActiveSupport::Notifications. +handler+ is required (name, data) → void.
      def webhooks(*patterns, handler:)
        raise ArgumentError, "ext.webhooks requires a handler:" if handler.nil?

        @webhook_patterns = patterns.flatten
        @webhook_handler = handler
      end

      # Register an outbound webhook event (catalog + OpenAPI + permission checkbox source).
      # +example+ is a callable +(organization) -> Hash+ (delivery envelope). Pair with
      # +webhooks(…, handler:)+ to wire Decidim notifications to a job.
      def webhook_event(event_name, scope:, example:, payload_schema_ref: nil, schema_key: nil, trigger: nil, permission: nil, description: nil) # rubocop:disable Metrics/ParameterLists
        raise ArgumentError, "ext.webhook_event requires example:" unless example.respond_to?(:call)

        @webhook_events << {
          event_name: event_name.to_s,
          scope: scope.to_sym,
          example:,
          payload_schema_ref: payload_schema_ref&.to_sym,
          schema_key: schema_key&.to_s,
          trigger: trigger.to_s.presence,
          permission: (permission || event_name).to_s,
          description: description.to_s.presence
        }
      end

      # Optional JSON:API serializer extensions + conditional GET hooks for a host serializer.
      # If +serializer+ does not resolve (+safe_constantize+), registration is skipped (no error).
      # See +website/docs/dev/add-endpoint/binding-and-relations.md+.
      def rest_enhancement(serializer:, http_cache_profile: nil, &block)
        builder = Core::RestEnhancementBuilder.new(
          extension_name: @name,
          serializer_name: serializer.to_s,
          http_cache_profile:
        )
        builder.instance_eval(&block) if block
        builder.validate_http_cache_strictness!
        @rest_enhancement_registrations << builder.to_registration
      end

      def apply!
        register_toggle_feature!
        register_oauth_scopes!
        register_permissions!
        register_routes!
        register_rswag_specs!
        register_open_api_definitions!
        register_webhook_events!
        register_webhooks!
        register_rest_enhancements!
      end

      private

      attr_reader :name

      def register_toggle_feature!
        return unless @toggle_feature_name

        Core::ModuleAvailability.register_feature!(@toggle_feature_name, gem: @toggle_feature_gem)
        Array(@controller_paths).each do |segment|
          Core::ModuleAvailability.register_controller_path!(segment, feature: @toggle_feature_name)
        end
        Array(@oauth_scopes).each do |scope|
          next if Core::ModuleAvailability.scope_features.has_key?(scope.to_sym)

          Core::ModuleAvailability.register_scope_feature!(scope, @toggle_feature_name)
        end
      end

      def register_rest_enhancements!
        @rest_enhancement_registrations.each do |reg|
          register_fingerprint_contribution!(reg)
          Core::SerializerAdditionsRegistry.register(reg)
        end
      end

      def register_fingerprint_contribution!(reg)
        return unless reg.http_cache_profile
        return unless reg.cache_time_proc || reg.etag_segment_proc

        Core::HttpCache::FingerprintContributorRegistry.register(
          reg.http_cache_profile,
          extension_name: reg.extension_name,
          cache_time: reg.cache_time_proc,
          etag_segment: reg.etag_segment_proc
        )
      end

      def register_oauth_scopes!
        return unless @oauth_scopes&.any?

        self.class.doorkeeper_optional_scopes.concat(@oauth_scopes)
        self.class.doorkeeper_optional_scopes.uniq!
        Core::DoorkeeperConfig.merge_optional_scopes! if Rails.application.initialized?
      end

      def register_permissions!
        return unless @permissions

        @permissions.each do |entry|
          Core::PermissionRegistry.register(entry[:scope], entry[:permission], group: entry[:group])
          merge_available_permission!(entry[:scope], entry[:permission])
        end
      end

      def register_routes!
        return unless @routes_block

        Routes.draw_api_routes(&@routes_block)
        Routes.append_pending! if Routes.applied?
      end

      def register_rswag_specs!
        return unless @rswag_specs&.any?

        @rswag_specs.each do |glob|
          Core::SwaggerSpecPaths.register(glob) if Dir[glob].any?
        end
      end

      def register_open_api_definitions!
        return unless @open_api_definitions&.any?

        @open_api_definitions.each do |path|
          Core::OpenApiDefinitionPaths.register(path)
        end
      end

      def register_webhook_events!
        return if @webhook_events.empty?

        @webhook_events.each do |entry|
          Core::WebhookEventCatalog.register(
            entry[:event_name],
            scope: entry[:scope],
            permission_key: entry[:permission],
            description: entry[:description],
            payload_schema_ref: entry[:payload_schema_ref],
            trigger: entry[:trigger],
            schema_key: entry[:schema_key],
            example: entry[:example]
          )
          Core::PermissionRegistry.register(
            entry[:scope],
            entry[:permission],
            group: :webhooks,
            event: true
          )
          merge_available_permission!(entry[:scope], entry[:permission])
        end
      end

      def merge_available_permission!(scope, permission)
        perms = Core::Configuration.available_permissions
        scope_key = scope.to_s
        perms[scope_key] ||= []
        perms[scope_key] << permission unless perms[scope_key].include?(permission)
      end

      def register_webhooks!
        return unless @webhook_patterns&.any?

        @webhook_patterns.each do |pattern|
          ActiveSupport::Notifications.subscribe(pattern) do |event_name, data|
            @webhook_handler.call(event_name, data)
          end
        end
      end
    end
  end
end
