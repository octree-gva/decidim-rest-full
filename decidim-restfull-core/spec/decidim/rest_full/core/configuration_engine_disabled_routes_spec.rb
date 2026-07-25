# frozen_string_literal: true

require "spec_helper"

# Toggle off → HTTP 501 (routes stay mounted; runtime ModuleAvailability enforces).
RSpec.describe "disabled RestFull modules via Toggle", type: :request do
  let(:organization) { create(:organization, host: "test.example.org") }

  before do
    host!(organization.host)
    allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:raw_config)
      .and_return({ enabled: true, proposals_enabled: false, blogs_enabled: false }.with_indifferent_access)
  end

  it "returns 501 for proposals when proposals Toggle is off" do
    get "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/proposals"
    expect(response).to have_http_status(:not_implemented)
  end

  it "returns 501 for blogs when blogs Toggle is off" do
    get "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/blogs"
    expect(response).to have_http_status(:not_implemented)
  end
end
