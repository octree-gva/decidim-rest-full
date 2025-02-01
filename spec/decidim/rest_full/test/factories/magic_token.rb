# frozen_string_literal: true

FactoryBot.define do
  factory :magic_token, class: "Decidim::RestFull::MagicToken" do
    association :user, factory: :user
    magic_token { Devise.friendly_token(20) }
    expires_at { 5.minutes.from_now }
  end
end
