# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- behaviour scenario (multi-step HTTP)
RSpec.describe "Upsert user by phone via ROPC and set locale" do
  let!(:organization) do
    create(:organization, available_locales: %w(en fr), default_locale: "en")
  end
  let(:nickname) { "phone#{SecureRandom.hex(4)}" }
  let(:phone_number) { "+33600000000" }

  let!(:api_client) do
    c = create(:api_client, organization:, scopes: %w(oauth public))
    c.permissions = [
      Decidim::RestFull::Core::Permission.new(permission: "oauth.impersonate"),
      Decidim::RestFull::Core::Permission.new(permission: "oauth.read"),
      Decidim::RestFull::Core::Permission.new(permission: "oauth.extended_data.read")
    ]
    c.save!
    c
  end

  let(:api_prefix) { "/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }

  before { host!(organization.host) }

  it "registers via ROPC with phone_number extra, then exposes locale fr on users index" do
    post(
      "#{api_prefix}/oauth/token",
      params: {
        grant_type: "password",
        auth_type: "impersonate",
        username: nickname,
        client_id: api_client.client_id,
        client_secret: api_client.client_secret,
        scope: "oauth",
        meta: { register_on_missing: true },
        extra: { phone_number: }
      }.to_json,
      headers: json_headers
    )
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["access_token"]).to be_present

    user = Decidim::User.find_by!(nickname:, organization:)
    expect(user.extended_data["phone_number"]).to eq(phone_number)

    # No REST endpoint mutates locale; set via model then assert API read path.
    user.update!(locale: "fr")
    expect(user.reload.locale).to eq("fr")

    credential_token = create(
      :oauth_access_token,
      scopes: "oauth",
      resource_owner_id: nil,
      application: api_client
    )

    get(
      "#{api_prefix}/users",
      params: { "filter[id_in][]" => [user.id] },
      headers: { "Authorization" => "Bearer #{credential_token.token}" }
    )
    expect(response).to have_http_status(:ok)
    row = response.parsed_body["data"].find { |u| u["id"].to_i == user.id }
    expect(row).to be_present
    expect(row.dig("attributes", "locale")).to eq("fr")
  end
end
# rubocop:enable RSpec/DescribeClass
