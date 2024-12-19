# frozen_string_literal: true

# spec/factories/oauth_applications.rb
FactoryBot.define do
  factory :rest_full_permission, class: "Decidim::RestFull::Permission" do
    api_client { create(:api_client) }
    permission { "dummy" }
  end

  factory :api_client, class: "Decidim::RestFull::ApiClient" do
    name { Faker::App.name } # Generate a random app name
    redirect_uri { Faker::Internet.url } # Generate a random URL
    scopes { [] }
    association :organization, factory: :organization
    permissions { [] }
  end
end
