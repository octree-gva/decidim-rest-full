# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_registration, class: "Decidim::RestFull::Core::WebhookRegistration" do
    sequence(:url) { |n| "https://example.org/webhook/#{n}" }
    private_key { SecureRandom.hex(32) }
    subscriptions { ["proposal_creation.succeeded"] }
    api_client factory: [:api_client], scopes: ["public"]
  end
end
