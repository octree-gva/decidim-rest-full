# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::ApiJob do
  let!(:organization) { create(:organization, available_locales: ["en"]) }
  let!(:user) { create(:user, organization:, confirmed_at: Time.zone.now) }
  let!(:api_client) do
    c = create(:api_client, organization:, scopes: ["proposals"])
    c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "proposals.draft")]
    c.save!
    c
  end
  let!(:token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client) }

  let(:large_payload) do
    { "path" => {}, "data" => { "body" => "x" * 400_000 } }
  end

  let(:base_attrs) do
    {
      decidim_organization_id: organization.id,
      doorkeeper_access_token_id: token.id,
      oauth_application_id: token.application_id,
      resource_owner_id: token.resource_owner_id,
      command_key: "draft_proposals#create",
      status: "pending",
      payload: large_payload
    }
  end

  describe "payload size" do
    it "allows large payloads when no max is configured" do
      allow(Decidim::RestFull.config).to receive(:max_async_api_job_payload_bytes).and_return(nil)

      expect { described_class.compat_create!(base_attrs) }.not_to raise_error
    end

    it "rejects payloads over the configured max" do
      allow(Decidim::RestFull.config).to receive(:max_async_api_job_payload_bytes).and_return(256_000)

      expect { described_class.compat_create!(base_attrs) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "accepts payloads under the configured max" do
      allow(Decidim::RestFull.config).to receive(:max_async_api_job_payload_bytes).and_return(2_000_000)

      expect { described_class.compat_create!(base_attrs) }.not_to raise_error
    end
  end
end
