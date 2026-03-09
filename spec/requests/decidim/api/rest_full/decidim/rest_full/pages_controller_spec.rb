# frozen_string_literal: true

# GET / (API root): no auth, returns 200. Documents the entry point in OpenAPI.

require "swagger_helper"

RSpec.describe Decidim::RestFull::PagesController do
  path "/" do
    get "API root" do
      tags "API"
      produces "text/html", "application/json"
      operationId "apiRoot"
      description "API entry point. Links to documentation and OpenAPI spec. No authentication required."
      security []

      response "200", "API info or documentation page" do
        let!(:organization) { create(:organization, available_locales: ["en"]) }

        before { host! organization.host }

        run_test!(example_name: :ok) do |response|
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
