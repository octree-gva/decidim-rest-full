# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      DuplicateRouteBlockError = Class.new(StandardError)

      # Registry for API route blocks. {apply!} draws the +api/rest_full/vX+ scope
      # on the given routes; the optional core block draws core API routes, then
      # each block registered via {draw_api_routes} is run with the same scope.
      class RouteRegistry
        class << self
          def draw_api_routes(&block)
            route_blocks << block
          end

          attr_writer :core_routes_block

          def core_routes_defined?
            @core_routes_block
          end

          def apply!(routes, &core_block)
            core_block ||= @core_routes_block
            if rest_full_routes_drawn?(routes)
              append_pending!(routes)
              return
            end

            # Decidim route reload can clear paths while applied_block_ids persists (see spec/spec_helper.rb).
            @applied_block_ids = ::Set.new if applied_block_ids.any?

            return if core_block.nil? && route_blocks.empty?

            draw_full!(routes, core_block, route_blocks)
          end

          def append_pending!(routes)
            pending = pending_blocks
            return if pending.empty?

            draw_append!(routes, pending)
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
            route_blocks.reject { |block| applied_block_ids.include?(block_id(block)) }
          end

          def draw_full!(routes, core_block, blocks)
            evaluate = method(:evaluate_block!)
            routes.disable_clear_and_finalize = true
            routes.draw do
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
                    evaluate.call(self, core_block) if core_block
                    blocks.each { |block| evaluate.call(self, block) }
                  end
                end
              end
            end
            routes.disable_clear_and_finalize = false
            routes.finalize!
          end

          def draw_append!(routes, blocks)
            evaluate = method(:evaluate_block!)
            routes.disable_clear_and_finalize = true
            routes.draw do
              namespace :api do
                namespace :rest_full do
                  scope "v#{Decidim::RestFull.major_minor_version}" do
                    blocks.each { |block| evaluate.call(self, block) }
                  end
                end
              end
            end
            routes.disable_clear_and_finalize = false
            routes.finalize!
          end

          def evaluate_block!(mapper, block)
            assert_not_applied!(block)
            mapper.instance_eval(&block)
            mark_applied!(block)
          end

          def assert_not_applied!(block)
            return unless applied_block_ids.include?(block_id(block))

            raise DuplicateRouteBlockError,
                  "Route block already applied (object_id=#{block_id(block)}). " \
                  "Check for double Extension.register or to_prepare re-entry."
          end

          def mark_applied!(block)
            applied_block_ids << block_id(block)
          end

          def applied_block_ids
            @applied_block_ids ||= ::Set.new
          end

          def block_id(block)
            block.object_id
          end

          def rest_full_routes_drawn?(routes)
            routes.routes.any? { |r| r.path.spec.to_s.include?("/api/rest_full/v") }
          end
        end
      end
    end
  end
end
