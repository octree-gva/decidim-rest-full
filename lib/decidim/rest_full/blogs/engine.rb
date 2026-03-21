# frozen_string_literal: true

module Decidim
  module RestFull
    module Blogs
      class Engine < ::Rails::Engine
        config.root = Pathname.new(File.expand_path("../../../..", __dir__))

        initializer "rest_full.blogs.permissions" do
          Decidim::RestFull::Core::PermissionRegistry.register(:blogs, "blogs.read", group: :blogs) if Decidim::RestFull::Core::Configuration.enable_blogs_api
        end

        initializer "rest_full.blogs.routes" do
          Decidim::RestFull::Core::RouteRegistry.draw_api_routes do
            constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_blogs_api }) do
              resources :components, only: [] do
                collection do
                  resources :blog_components,
                            only: [:index, :show],
                            controller: "/decidim/api/rest_full/components/blog_components"
                end
              end

              resources :blogs,
                        only: [:index, :show],
                        controller: "/decidim/api/rest_full/blogs/blogs"
            end
          end
        end
      end
    end
  end
end
