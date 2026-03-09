# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_registration, class: "Decidim::RestFull::WebhookRegistration" do
    url { Faker::Internet.url }
    private_key { Faker::Internet.password(min_length: 64, max_length: 64) }
    subscriptions { ["event.subscribed"] }
    api_client factory: [:api_client], scopes: ["public"]
  end
end
