# frozen_string_literal: true

module Decidim
  module RestFull
    module Test
      class GlobalContext < ActiveSupport::CurrentAttributes
        attribute :security_type
      end
    end
  end
end
