# frozen_string_literal: true

# spec/support/api_schemas/organization_schema.rb
module Api
  module Definitions
    USER_EXTENDED_DATA = {
      type: :object,
      title: "User extended data",
      properties: {},
      additionalProperties: true,
      description: <<~README
        Hash of values attached to a user. These values won't be
        displayed to admins or users, consider this as an internal
        data payload.
      README
    }.freeze
  end
end
