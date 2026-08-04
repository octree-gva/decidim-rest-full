# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        class WebhookRegistrationSerializer < ApplicationSerializer
          set_type :webhook_registration

          attributes :url, :subscriptions

          attribute :signing_secret, if: proc { |_record, params| params && params[:include_signing_secret] }, &:private_key

          attribute :created_at do |registration|
            registration.created_at&.iso8601
          end

          attribute :updated_at do |registration|
            registration.updated_at&.iso8601
          end
        end
      end
    end
  end
end
