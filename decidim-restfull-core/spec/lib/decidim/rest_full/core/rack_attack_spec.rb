# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::RackAttack do
  describe ".register_ropc_request?" do
    let(:env) { {} }
    let(:body_io) { StringIO.new(body_json) }
    let(:body_json) do
      {
        auth_type: "impersonate",
        client_id: "client12345",
        meta: { register_on_missing: true }
      }.to_json
    end
    let(:req) do
      instance_double(
        Rack::Request,
        post?: true,
        path: "/oauth/token",
        content_type: "application/json",
        body: body_io,
        env:,
        host: "example.org",
        params: {}
      )
    end

    before do
      allow(body_io).to receive(:rewind)
    end

    it "returns true for impersonate register_on_missing" do
      expect(described_class.register_ropc_request?(req)).to be(true)
    end

    context "when register_on_missing is the string false" do
      let(:body_json) do
        {
          auth_type: "impersonate",
          client_id: "client12345",
          meta: { register_on_missing: "false" }
        }.to_json
      end

      it "returns false" do
        expect(described_class.register_ropc_request?(req)).to be(false)
      end
    end

    context "when auth_type is login" do
      let(:body_json) do
        { auth_type: "login", client_id: "client12345" }.to_json
      end

      it "returns false" do
        expect(described_class.register_ropc_request?(req)).to be(false)
      end
    end
  end

  describe ".install!" do
    it "skips when register_per_minute is 0" do
      allow(Decidim::RestFull.config).to receive(:register_per_minute).and_return(0)
      expect(::Rack::Attack).not_to receive(:throttle) if defined?(::Rack::Attack)
      described_class.install!
    end
  end

  describe ".discriminator_for" do
    let(:organization) { create(:organization) }
    let(:env) { { "decidim.current_organization" => organization } }
    let(:body_io) { StringIO.new(body_json) }
    let(:body_json) do
      {
        auth_type: "impersonate",
        client_id: "client12345",
        meta: { register_on_missing: true }
      }.to_json
    end
    let(:req) do
      instance_double(
        Rack::Request,
        post?: true,
        path: "/api/rest_full/v0.1/oauth/token",
        content_type: "application/json",
        body: body_io,
        env:,
        host: organization.host,
        params: {}
      )
    end

    before { allow(body_io).to receive(:rewind) }

    it "keys by org host and client_id" do
      expect(described_class.discriminator_for(req)).to eq("#{organization.host}:client12345")
    end
  end
end
