# frozen_string_literal: true

# spec/factories/oauth_applications.rb
FactoryBot.define do
  factory :api_client, class: "Decidim::RestFull::ApiClient" do
    name { Faker::App.name } # Generate a random app name
    redirect_uri { Faker::Internet.url } # Generate a random URL
    scopes { "public" }
    organization { create(:organization) }
  end
end
