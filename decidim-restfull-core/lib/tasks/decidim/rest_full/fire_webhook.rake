# frozen_string_literal: true

namespace :decidim_rest_full do
  desc <<~DESC.tr("\n", " ")
    POST a typed sample webhook envelope to a URL.
    ENV: URL (required), EVENT (required catalog name or alias), HOST (org host, optional),
    ORGANIZATION_ID (optional), SECRET (HMAC secret, optional — generated and printed if omitted),
    DRY_RUN=1 (print payload only). EVENT=list prints known events.
  DESC
  task fire_webhook: :environment do
    if ENV["EVENT"].to_s.strip == "list"
      puts Decidim::RestFull::Core::FireWebhook.known_events.join("\n")
      next
    end

    organization = Decidim::RestFull::Core::FireWebhook.resolve_organization!(
      organization_id: ENV["ORGANIZATION_ID"],
      host: ENV["HOST"]
    )
    event = ENV.fetch("EVENT") { raise ArgumentError, "EVENT is required (or EVENT=list)" }
    url = ENV.fetch("URL") { raise ArgumentError, "URL is required" }

    if ENV["DRY_RUN"].to_s == "1"
      event_name = Decidim::RestFull::Core::FireWebhook.resolve_event_name!(event)
      payload = Decidim::RestFull::Core::WebhookEventCatalog.example_payload_for(
        event_name,
        organization:
      )
      puts({ event: event_name, organization_id: organization.id, payload: }.to_json)
      next
    end

    result = Decidim::RestFull::Core::FireWebhook.call(
      url:,
      event:,
      organization:,
      secret: ENV.fetch("SECRET", nil)
    )

    puts({
      event: result.event_name,
      url: result.url,
      status: result.status_code,
      signing_secret: result.secret,
      timestamp: result.timestamp,
      payload: result.payload,
      response_body: result.body.to_s[0, 500]
    }.to_json)

    abort "Webhook endpoint returned HTTP #{result.status_code}" unless result.status_code.between?(200, 299)
  end
end
