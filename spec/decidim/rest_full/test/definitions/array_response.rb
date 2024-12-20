# frozen_string_literal: true

module Api
  module Definitions
    def self.array_response(ref, title)
      {
        type: :object,
        title: title,
        properties: {
          data: {
            type: :array,
            items: { "$ref" => "#/components/schemas/#{ref}" }
          }
        },
        required: [:data]
      }
    end
  end
end
