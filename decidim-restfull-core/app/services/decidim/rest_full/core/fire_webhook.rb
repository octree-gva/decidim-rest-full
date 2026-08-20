# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Dev/integrator helper: POST a typed sample webhook envelope to an arbitrary URL.
      class FireWebhook
        # Short / Decidim-notification aliases → catalog event names.
        ALIASES = {
          "decidim.step_activated" => "participatory_process.step_activated.succeeded",
          "decidim.events.participatory_process.step_activated" => "participatory_process.step_activated.succeeded",
          "step_activated" => "participatory_process.step_activated.succeeded",
          "phase_change" => "participatory_process.step_activated.succeeded",
          "proposal_published" => "proposal_creation.succeeded",
          "decidim.events.proposals.proposal_published" => "proposal_creation.succeeded",
          "proposal_created" => "proposal_creation.succeeded"
        }.freeze

        Result = Struct.new(:event_name, :url, :status_code, :body, :secret, :payload, :timestamp, keyword_init: true)

        def self.call(url:, event:, organization:, secret: nil)
          new(url:, event:, organization:, secret:).call
        end

        def self.resolve_event_name!(query)
          q = query.to_s.strip
          raise ArgumentError, "EVENT is required" if q.blank?

          return ALIASES[q] if ALIASES.has_key?(q)
          return q if WebhookEventCatalog.find(q)

          matches = WebhookEventCatalog.all.select do |entry|
            entry.event_name.include?(q) || entry.event_name.end_with?(q)
          end
          raise ArgumentError, "Unknown webhook event #{q.inspect}. Known: #{known_events.join(", ")}" if matches.empty?
          raise ArgumentError, "Ambiguous event #{q.inspect}: #{matches.map(&:event_name).join(", ")}" if matches.size > 1

          matches.first.event_name
        end

        def self.known_events
          WebhookEventCatalog.all.map(&:event_name)
        end

        def self.resolve_organization!(organization_id: nil, host: nil)
          if organization_id.present?
            Decidim::Organization.find(organization_id)
          elsif host.present?
            Decidim::Organization.find_by!(host:)
          else
            org = Decidim::Organization.first
            raise ArgumentError, "No organization found — set HOST or ORGANIZATION_ID" unless org

            org
          end
        end

        def initialize(url:, event:, organization:, secret: nil)
          @url = url.to_s.strip
          @event_query = event
          @organization = organization
          @secret = secret.to_s.presence || SecureRandom.hex(32)
        end

        def call
          validate_url!
          event_name = self.class.resolve_event_name!(@event_query)
          envelope = WebhookEventCatalog.example_payload_for(event_name, organization: @organization)
          timestamp = Time.current.to_i.to_s
          json_payload = envelope.to_json
          response = post!(json_payload, timestamp)

          Result.new(
            event_name:,
            url: @url,
            status_code: response.code.to_i,
            body: response.body.to_s,
            secret: @secret,
            payload: envelope,
            timestamp:
          )
        end

        private

        def validate_url!
          raise ArgumentError, "URL is required" if @url.blank?

          uri = URI.parse(@url)
          raise ArgumentError, "URL must be http(s)" unless %w(http https).include?(uri.scheme)
          raise ArgumentError, "URL must include a host" if uri.host.blank?
        rescue URI::InvalidURIError => e
          raise ArgumentError, "Invalid URL: #{e.message}"
        end

        def post!(json_payload, timestamp)
          uri = URI.parse(@url)
          signature = "v1=#{OpenSSL::HMAC.hexdigest("SHA256", @secret, "#{timestamp}.#{json_payload}")}"
          headers = {
            "Content-Type" => "application/json",
            "X-Webhook-Signature" => signature,
            "X-Webhook-Timestamp" => timestamp,
            "User-Agent" => "decidim-restfull-fire-webhook/1"
          }
          request = Net::HTTP::Post.new(uri, headers)
          request.body = json_payload
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.request(request)
          end
        end
      end
    end
  end
end
