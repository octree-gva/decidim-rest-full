# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Api::RestFull::Components::ComponentsController do
  describe "search SQL pagination" do
    let!(:organization) { create(:organization) }
    let!(:user) { create(:user, :admin, organization:) }
    let!(:api_client) do
      c = create(:api_client, organization:, scopes: ["public"])
      c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "public.component.read")]
      c.save!
      c
    end
    let!(:token) { create(:oauth_access_token, scopes: "public", resource_owner_id: user.id, application: api_client) }
    let(:api_prefix) { "/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }
    let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }

    before do
      host!(organization.host)
      12.times do
        create(:component, participatory_space: participatory_process, manifest_name: :meetings, published_at: Time.zone.now)
      end
    end

    it "applies SQL LIMIT before serializing components" do
      sql = []
      callback = lambda do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        sql << event.payload[:sql] if event.payload[:sql].match?(/decidim_components/i)
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get(
          "#{api_prefix}/components/search",
          params: { page: 1, per_page: 2 },
          headers: { "Authorization" => "Bearer #{token.token}" }
        )
      end

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"].size).to eq(2)
      joined = sql.join("\n")
      expect(joined).to match(/\bLIMIT\b/i)
      expect(joined).to match(/\bOFFSET\b/i)
    end
  end
end
