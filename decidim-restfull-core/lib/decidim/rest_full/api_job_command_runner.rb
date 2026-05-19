# frozen_string_literal: true

module Decidim
  module RestFull
    # Maps persisted ApiJob.command_key to service calls (sync + async).
    #
    # Extensions register handlers from an engine initializer, e.g.:
    #   Decidim::RestFull::ApiJobCommandRunner.register("widgets#create") do |ctx, p|
    #     Widgets::WidgetOperations.new(ctx, p).create!
    #   end
    class ApiJobCommandRunner
      DEFAULT_HANDLERS = {
        "organizations#update" => ->(ctx, p) { Core::ApiSystemOperations.new(ctx, p).organizations_update! },
        "organization_extended_data#update" => ->(ctx, p) { Core::ApiSystemOperations.new(ctx, p).organization_extended_data_update! },
        "user_extended_data#update" => ->(ctx, p) { Core::ApiSystemOperations.new(ctx, p).user_extended_data_update! },
        "roles#create" => ->(ctx, p) { Core::ApiSystemOperations.new(ctx, p).roles_create! },
        "roles#destroy" => ->(ctx, p) { Core::ApiSystemOperations.new(ctx, p).roles_destroy! }
      }.freeze

      class << self
        # @param command_key [String]
        # @param callable [#call] proc/lambda/method object (ctx, params) -> result
        def register(command_key, callable = nil, &block)
          handler = callable || block
          raise ArgumentError, "handler must respond to #call" unless handler.respond_to?(:call)

          handlers[command_key.to_s] = handler
        end

        def unregister(command_key)
          handlers.delete(command_key.to_s)
        end

        def handlers
          @handlers ||= {}.merge(DEFAULT_HANDLERS)
        end

        def run!(ctx, command_key, params)
          handler = handlers[command_key.to_s]
          raise ArgumentError, "Unknown command_key: #{command_key}" unless handler

          handler.call(ctx, params)
        end
      end
    end
  end
end
