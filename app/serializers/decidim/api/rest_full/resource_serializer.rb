# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ResourceSerializer < ApplicationSerializer
        belongs_to :component, record_type: :component
        belongs_to :participatory_space, record_type: :space
      end
    end
  end
end
