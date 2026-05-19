# frozen_string_literal: true

FactoryBot.define do
  factory :magic_token, class: "Decidim::RestFull::Core::MagicToken" do
    user factory: [:user]
    magic_token { Devise.friendly_token(20) }
    expires_at { 5.minutes.from_now }

    trait :with_redirect_url do
      redirect_url { "https://example.org/callback" }
    end
  end
end
