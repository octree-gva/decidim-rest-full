# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      DuplicateRouteBlockError = Class.new(StandardError)

      # Collects API route blocks and draws them under /api/rest_full/vX.
      # Boot path: Routes.mount! → RouteSet#append (like Decidim Admin). Do not finalize!
      class RouteRegistry
        class << self
          def draw_api_routes(&block)
            route_blocks << block
          end

          attr_writer :core_routes_block

          def core_routes_defined?
            @core_routes_block
          end

          # Draw into a Mapper (from RouteSet#append or routes.draw).
          def draw_routes_on(mapper, core_block = @core_routes_block)
            # Reloader clear! drops paths; applied ids can linger.
            @applied_block_ids = ::Set.new if applied_block_ids.any?

            blocks = route_blocks
            return if core_block.nil? && blocks.empty?

            registry = self
            mapper.instance_eval do
              authenticate(:admin) do
                namespace "system" do
                  resources :api_clients, controller: "/decidim/rest_full/system/api_clients"
                  resources :api_permissions, only: [:create], controller: "/decidim/rest_full/system/permissions"
                  resources :webhook_registrations, only: [:create, :destroy], controller: "/decidim/rest_full/system/webhook_registrations"
                end
              end

              namespace :api do
                namespace :rest_full do
                  scope "v#{Decidim::RestFull.major_minor_version}" do
                    registry.evaluate_block!(self, core_block) if core_block
                    blocks.each { |block| registry.evaluate_block!(self, block) }
                  end
                end
              end
            end
          end

          def apply!(routes, &core_block)
            core_block ||= @core_routes_block
            if rest_full_routes_drawn?(routes)
              append_pending!(routes)
              return
            end

            return if core_block.nil? && route_blocks.empty?

            # No finalize! — Devise locks Warden on the first one.
            routes.disable_clear_and_finalize = true
            routes.draw { Decidim::RestFull::Core::RouteRegistry.draw_routes_on(self, core_block) }
            routes.disable_clear_and_finalize = false
          end

          def append_pending!(routes)
            pending = pending_blocks
            return if pending.empty?

            registry = self
            routes.disable_clear_and_finalize = true
            routes.draw do
              namespace :api do
                namespace :rest_full do
                  scope "v#{Decidim::RestFull.major_minor_version}" do
                    pending.each { |block| registry.evaluate_block!(self, block) }
                  end
                end
              end
            end
            routes.disable_clear_and_finalize = false
          end

          def evaluate_block!(mapper, block)
            if applied_block_ids.include?(block.object_id)
              raise DuplicateRouteBlockError,
                    "Route block already applied (object_id=#{block.object_id}). " \
                    "Check for double Extension.register or to_prepare re-entry."
            end

            mapper.instance_eval(&block)
            applied_block_ids << block.object_id
          end

          def route_blocks
            @route_blocks ||= []
          end

          def reset!
            @route_blocks = []
            @core_routes_block = nil
            @applied_block_ids = nil
          end

          private

          def pending_blocks
            route_blocks.reject { |block| applied_block_ids.include?(block.object_id) }
          end

          def applied_block_ids
            @applied_block_ids ||= ::Set.new
          end

          def rest_full_routes_drawn?(routes)
            routes.routes.any? { |r| r.path.spec.to_s.include?("/api/rest_full/v") }
          end
        end
      end
    end
  end
end
