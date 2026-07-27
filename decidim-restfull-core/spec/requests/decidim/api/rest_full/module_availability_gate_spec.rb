# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- request integration for ModuleAvailability gates
RSpec.describe "RestFull ModuleAvailability API gates" do
  let(:organization) { create(:organization, host: "test.example.org") }
  let(:api_client) { create(:api_client, organization:, scopes: %w(public blogs)) }
  let(:user) { create(:user, :confirmed, organization:) }
  let!(:token) do
    create(:oauth_access_token, scopes: "public blogs", resource_owner_id: user.id, application: api_client)
  end
  let(:version) { Decidim::RestFull.major_minor_version }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Host" => organization.host } }

  before do
    host!(organization.host)
  end

  def stub_toggle(hash)
    allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:raw_config)
      .and_return(hash.with_indifferent_access)
  end

  it "returns 501 on core endpoints when master is off" do
    stub_toggle(enabled: false)
    get("/api/rest_full/v#{version}/organizations", headers:)
    expect(response).to have_http_status(:not_implemented)
    expect(response.parsed_body["error"]).to include("501")
  end

  it "returns 501 on blogs endpoints when blogs is off" do
    stub_toggle(enabled: true, blogs_enabled: false)
    get("/api/rest_full/v#{version}/blogs", headers:)
    expect(response).to have_http_status(:not_implemented)
    expect(response.parsed_body["error"]).to include("501")
  end

  it "allows core endpoints when only blogs is off" do
    stub_toggle(enabled: true, blogs_enabled: false)
    get("/api/rest_full/v#{version}/spaces/search", headers:)
    # may be 200 or 403 depending on permissions; must not be 501
    expect(response).not_to have_http_status(:not_implemented)
  end
end
# rubocop:enable RSpec/DescribeClass
