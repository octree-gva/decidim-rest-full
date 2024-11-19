# frozen_string_literal: true

module Api
  module Definitions
    POPULATE_PARAM = lambda do |serializer|
      {
        type: :array,
        items: { type: :string, enum: serializer.db_fields }
      }
    end
  end
end
