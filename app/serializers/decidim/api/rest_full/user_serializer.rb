# frozen_string_literal: true

# app/serializers/decidim/rest_full/organization_serializer.rb
module Decidim
  module Api
    module RestFull
      class UserSerializer < ApplicationSerializer
        attributes :name, :nickname, :personal_url, :email, :about

        attribute :extended_data do |usr, params|
          params[:includes_extended] ? usr.extended_data : {}
        end

        attribute :locale do |usr|
          usr.locale || usr.organization.default_locale || Decidim.default_locale
        end

        attribute :created_at do |usr|
          usr.created_at.iso8601
        end

        attribute :updated_at do |usr|
          usr.updated_at.iso8601
        end

        has_many :roles do |_usr|
          []
        end

        meta do |user|
          {
            blocked: user.blocked_at.present?,
            locked: user.locked_at.present?
          }
        end
      end
    end
  end
end
