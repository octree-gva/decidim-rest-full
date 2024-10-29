# frozen_string_literal: true

module Decidim
  module RestFull
    module Entities
      class MetaEntity < Grape::Entity
        expose :populated, documentation: { type: "string", is_array: true, desc: "Populated fields" }
        expose :locales, documentation: { type: "string", is_array: true, desc: "Selected locales" }
      end
    end
  end
end
