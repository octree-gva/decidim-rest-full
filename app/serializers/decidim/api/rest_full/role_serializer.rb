# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class RoleSerializer < ApplicationSerializer
        attributes :type, :user_id, :resource_id, :resource_type, :invited_at, :accepted_invite

        attribute :created_at do |role|
          role.created_at&.iso8601
        end

        attribute :updated_at do |role|
          role.updated_at&.iso8601
        end
      end
    end
  end
end
