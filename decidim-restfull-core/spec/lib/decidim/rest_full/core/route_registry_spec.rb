# frozen_string_literal: true

# RouteRegistry: API route blocks are registered with draw_api_routes and drawn in
# the api/rest_full/vX scope when apply! is called. These specs use an isolated
# RouteSet so we don't touch the real app routes.

require "spec_helper"

module Decidim
  module RestFull
    module Core
      RSpec.describe RouteRegistry do
        after { described_class.reset! }

        describe ".draw_api_routes" do
          it "appends the block to route_blocks" do
            block = proc {}
            described_class.draw_api_routes(&block)
            expect(described_class.route_blocks).to include(block)
          end
        end

        describe ".apply! with isolated RouteSet" do
          it "runs registered blocks in the api scope and adds routes" do
            described_class.draw_api_routes do
              get "/_spec_ping", to: "/decidim/rest_full/pages#show"
            end
            isolated = ActionDispatch::Routing::RouteSet.new
            described_class.apply!(isolated) do
              get "/", to: "/decidim/rest_full/pages#show"
            end

            path_specs = isolated.routes.map { |r| r.path.spec.to_s }
            expect(path_specs).to include(include("_spec_ping"))
          end

          it "preserves pre-existing routes (e.g. Doorkeeper /oauth/token at org root)" do
            isolated = ActionDispatch::Routing::RouteSet.new
            isolated.draw do
              post "/oauth/token", to: "doorkeeper/tokens#create"
            end
            count_before = isolated.routes.count

            described_class.apply!(isolated) do
              get "/", to: "/decidim/rest_full/pages#show"
            end

            path_specs = isolated.routes.map { |r| r.path.spec.to_s }
            expect(isolated.routes.count).to be > count_before
            expect(path_specs).to include("/oauth/token(.:format)")
            expect(path_specs).to include(a_string_matching(%r{/api/rest_full/v[\d.]+(\(\.:format\)|/)}))
          end

          it "appends routes registered after the first apply!" do
            isolated = ActionDispatch::Routing::RouteSet.new
            described_class.apply!(isolated) { get "/", to: "/decidim/rest_full/pages#show" }

            described_class.draw_api_routes do
              get "/_spec_late", to: "/decidim/rest_full/pages#show"
            end

            described_class.append_pending!(isolated)

            path_specs = isolated.routes.map { |r| r.path.spec.to_s }
            expect(path_specs).to include(include("_spec_late"))
          end

          it "raises DuplicateRouteBlockError when the same block is registered twice" do
            block = proc { get "/_spec_dup", to: "/decidim/rest_full/pages#show" }
            described_class.draw_api_routes(&block)
            described_class.draw_api_routes(&block)

            isolated = ActionDispatch::Routing::RouteSet.new
            expect do
              described_class.apply!(isolated) { get "/", to: "/decidim/rest_full/pages#show" }
            end.to raise_error(Decidim::RestFull::Core::DuplicateRouteBlockError, /already applied/)
          end
        end

        describe ".reset!" do
          it "clears route_blocks" do
            described_class.draw_api_routes { get "/x", to: "x#y" }
            described_class.reset!
            expect(described_class.route_blocks).to eq([])
          end
        end
      end
    end
  end
end
