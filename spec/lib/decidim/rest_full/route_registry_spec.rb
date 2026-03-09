# frozen_string_literal: true

# RouteRegistry: API route blocks are registered with draw_api_routes and drawn in
# the api/rest_full/vX scope when apply! is called. These specs use an isolated
# RouteSet so we don't touch the real app routes.

require "spec_helper"

module Decidim
  module RestFull
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
