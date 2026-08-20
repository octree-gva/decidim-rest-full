# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- behaviour scenario (multi-step HTTP)
RSpec.describe "Blog published_at DESC prev/next chain" do
  let!(:organization) { create(:organization, available_locales: %w(en fr)) }
  let!(:participatory_process) { create(:participatory_process, organization:) }
  let!(:component) do
    create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now)
  end
  let!(:newest) { create(:post, component:, published_at: 1.day.ago) }
  let!(:middle) { create(:post, component:, published_at: 2.days.ago) }
  let!(:oldest) { create(:post, component:, published_at: 3.days.ago) }

  let!(:api_client) do
    c = create(:api_client, organization:, scopes: ["blogs"])
    c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "blogs.read")]
    c.save!
    c
  end
  let!(:token) do
    create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client)
  end

  let(:api_prefix) { "/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }
  let(:auth_headers) { { "Authorization" => "Bearer #{token.token}" } }
  let(:chain_params) do
    {
      component_id: component.id,
      space_id: participatory_process.id,
      space_manifest: "participatory_processes",
      order: "published_at",
      order_direction: "desc"
    }
  end

  before { host!(organization.host) }

  def get_blog(id)
    get("#{api_prefix}/blogs/#{id}", params: chain_params, headers: auth_headers)
  end

  def follow_next!(data)
    next_link = data.dig("links", "next")
    expect(next_link).to be_present
    get_blog(next_link.dig("meta", "resource_id"))
    expect(response).to have_http_status(:ok)
    response.parsed_body["data"]
  end

  it "walks newest → middle → oldest with nil prev on first and nil next on last" do
    get_blog(newest.id)
    expect(response).to have_http_status(:ok)
    first = response.parsed_body["data"]
    expect(first["id"].to_i).to eq(newest.id)
    expect(first.dig("links", "prev")).to be_nil
    expect(first.dig("links", "next", "meta", "resource_id").to_i).to eq(middle.id)

    second = follow_next!(first)
    expect(second["id"].to_i).to eq(middle.id)
    expect(second.dig("links", "prev", "meta", "resource_id").to_i).to eq(newest.id)
    expect(second.dig("links", "next", "meta", "resource_id").to_i).to eq(oldest.id)

    third = follow_next!(second)
    expect(third["id"].to_i).to eq(oldest.id)
    expect(third.dig("links", "next")).to be_nil
    expect(third.dig("links", "prev", "meta", "resource_id").to_i).to eq(middle.id)
  end
end
# rubocop:enable RSpec/DescribeClass
