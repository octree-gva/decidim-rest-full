# frozen_string_literal: true

# app/serializers/decidim/rest_full/organization_serializer.rb
module Decidim
  module Api
    module RestFull
      class UserSerializer < ApplicationSerializer
        attributes :name, :nickname, :personal_url, :email, :about
        attribute :locale do |usr|
          usr.locale || usr.organization.default_locale || Decidim.default_locale
        end
        attribute :created_at do |usr|
          usr.created_at.iso8601
        end

        attribute :updated_at do |usr|
          usr.updated_at.iso8601
        end
      end
    end
  end
end
