# frozen_string_literal: true

module Decidim
  module RestFull
    module Blogs
      class Engine < ::Rails::Engine
        config.root = Blogs::ENGINE_ROOT

        initializer "rest_full.blogs.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_blogs_api

          Decidim::RestFull::Extension.register(:blogs) do |ext|
            ext.oauth_scopes :blogs
            ext.permissions(:blogs, "blogs.read", group: :blogs)
            ext.permissions(:blogs, "blogs.write", group: :blogs)
            ext.permissions(:blogs, "blogs.destroy", group: :blogs)

            ext.api_job "blogs/posts#create", ->(ctx, p) { Blogs::BlogsOperations.new(ctx, p).create! }
            ext.api_job "blogs/posts#update", ->(ctx, p) { Blogs::BlogsOperations.new(ctx, p).update! }
            ext.api_job "blogs/posts#destroy", ->(ctx, p) { Blogs::BlogsOperations.new(ctx, p).destroy! }

            ext.open_api_definitions(
              File.join(Blogs::ENGINE_ROOT, "lib/decidim/rest_full/blogs/test_definitions.rb")
            )

            ext.rswag_specs(
              File.join(Blogs::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/blogs/**/*_spec.rb"),
              File.join(Blogs::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/components/blog_components*_spec.rb")
            )

            ext.routes do
              constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_blogs_api }) do
                resources :components, only: [] do
                  collection do
                    Decidim::RestFull::Routing.read_resources(
                      self,
                      :blog_components,
                      controller: "components/blog_components",
                      only: [:index, :show]
                    )
                  end
                end

                Decidim::RestFull::Routing.async_resources(
                  self,
                  :blogs,
                  controller: "blogs/blogs",
                  only: [:index, :show, :create, :update, :destroy]
                )
              end
            end
          end
        end
      end
    end
  end
end
