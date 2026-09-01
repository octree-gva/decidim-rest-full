# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- integration-style request examples
RSpec.describe "Decidim RestFull system API clients admin pages" do
  include Warden::Test::Helpers

  let!(:organization) { create(:organization, available_locales: ["en"]) }
  let!(:system_admin) { create(:admin) }
  let!(:api_client) { create(:api_client, organization:, scopes: %w(system public)) }

  before do
    login_as system_admin, scope: :admin
    host!(organization.host)
  end

  after { Warden.test_reset! }

  it "renders index, new, show, and edit without strict locals errors" do
    get Decidim::Core::Engine.routes.url_helpers.system_api_clients_path
    expect(response).to have_http_status(:ok)

    get Decidim::Core::Engine.routes.url_helpers.new_system_api_client_path
    expect(response).to have_http_status(:ok)

    get Decidim::Core::Engine.routes.url_helpers.system_api_client_path(api_client)
    expect(response).to have_http_status(:ok)

    get Decidim::Core::Engine.routes.url_helpers.edit_system_api_client_path(api_client)
    expect(response).to have_http_status(:ok)
  end

  it "renders extension-registered permissions on the edit form" do
    Decidim::RestFull::Core::PermissionRegistry.register(:whatsapp, "whatsapp.read", group: :whatsapp)
    client = create(:api_client, organization:, scopes: %w(whatsapp))

    get Decidim::Core::Engine.routes.url_helpers.edit_system_api_client_path(client)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("whatsapp.read")
  ensure
    Decidim::RestFull::Core::PermissionRegistry.send(:registry).delete("whatsapp.read")
  end
end
# rubocop:enable RSpec/DescribeClass
