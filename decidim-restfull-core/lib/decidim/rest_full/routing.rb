# frozen_string_literal: true

module Decidim
  module RestFull
    # Route helpers for +ext.routes+ blocks. Pass the router (+self+ inside the block) as the first argument.
    module Routing
      class << self
        def read_resources(router, name, **config)
          resources(router, name, **config)
        end

        def async_resources(router, name, **config)
          only = config.fetch(:only)
          member = config[:member]

          resources(router, name, **config) do
            router.collection { router.post "sync", action: :create_sync } if only.include?(:create)

            next unless only.intersect?([:update, :destroy]) || member

            router.member do
              router.put "sync", action: :update_sync if only.include?(:update)
              router.delete "sync", action: :destroy_sync if only.include?(:destroy)
              apply_member_actions(router, member) if member
            end
          end
        end

        private

        def resources(router, name, **config, &block)
          controller = config.fetch(:controller)
          only = config.fetch(:only, [:index, :show])
          options = config.except(:controller, :only, :member)

          if block
            router.resources name, only:, controller: absolutize(controller), **options, &block
          else
            router.resources name, only:, controller: absolutize(controller), **options
          end
        end

        def absolutize(controller)
          "/decidim/api/rest_full/#{controller}"
        end

        def apply_member_actions(router, actions)
          actions.each do |method, paths|
            paths.each do |path, action|
              router.public_send(method, path, action:)
            end
          end
        end
      end
    end
  end
end
