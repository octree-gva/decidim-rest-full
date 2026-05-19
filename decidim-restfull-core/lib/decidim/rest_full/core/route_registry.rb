# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
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
            return if routes.routes.any? { |r| r.path.spec.to_s.include?("/api/rest_full/v") }
            return if core_block.nil? && route_blocks.empty?

            blocks = route_blocks
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
                    instance_eval(&core_block) if core_block
                    blocks.each { |block| instance_eval(&block) }
                  end
                end
              end
            end
          end

          def route_blocks
            @route_blocks ||= []
          end

          def reset!
            @route_blocks = []
            @core_routes_block = nil
          end
        end
      end
    end
  end
end
