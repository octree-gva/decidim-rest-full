# frozen_string_literal: true

namespace :decidim_rest_full do
  desc "Seed a local-only integrator API client (stdout JSON). Idempotent by client id."
  task seed_integrator_sandbox: :environment do
    org = Decidim::Organization.first
    raise "No organization found — run db:seed first" unless org

    client_id = ENV.fetch("INTEGRATOR_SANDBOX_CLIENT_ID", "integrator-sandbox")
    api_client = Decidim::RestFull::Core::ApiClient.find_by(uid: client_id)
    unless api_client
      api_client = Decidim::RestFull::Core::ApiClient.new(
        uid: client_id,
        secret: ENV.fetch("INTEGRATOR_SANDBOX_CLIENT_SECRET", "integrator-sandbox-secret-change-me"),
        name: "Integrator sandbox (local dev)",
        scopes: %w(public proposals attachments),
        redirect_uri: "https://#{org.host || "localhost"}"
      )
      api_client.organization = org
      api_client.save!
      %w(public.component.read proposals.read proposals.draft proposals.vote attachments.read attachments.write).each do |perm|
        api_client.permissions.create!(permission: perm)
      end
    end

    host = org.host || ENV.fetch("INTEGRATOR_SANDBOX_HOST", "localhost")
    payload = {
      host:,
      organization_id: org.id,
      client_id: api_client.uid,
      client_secret: api_client.secret,
      scopes: api_client.scopes.to_a,
      permissions: api_client.permissions.pluck(:permission)
    }
    puts payload.to_json
  end
end
