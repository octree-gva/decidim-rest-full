# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Shared eligibility for resource-owner API use and ROPC token issue.
      module UserApiEligibility
        module_function

        def eligible?(user)
          user.present? && !user.blocked? && user.locked_at.blank? && user.confirmed_at.present?
        end

        def assert!(user)
          raise ApiException::BadRequest, "User required" unless user
          raise ApiException::BadRequest, "User blocked" if user.blocked? || user.blocked_at
          raise ApiException::BadRequest, "User locked" if user.locked_at.present?
          raise ApiException::BadRequest, "User unconfirmed" if user.confirmed_at.blank?

          true
        end
      end
    end
  end
end
