# frozen_string_literal: true

module Api
  module Definitions
    def self.item_response(ref, title)
      {
        type: :object,
        title: title,
        properties: {
          data: { "$ref" => "#/components/schemas/#{ref}" }
        },
        required: [:data]
      }
    end
  end
end
