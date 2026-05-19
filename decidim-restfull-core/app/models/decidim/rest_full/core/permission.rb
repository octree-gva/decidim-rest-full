# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class Permission < ::ApplicationRecord
        self.table_name = "decidim_rest_full_api_client_permissions"
        scope :events, -> { where(is_event: true) }
        belongs_to :api_client, class_name: "Decidim::RestFull::Core::ApiClient"

        validates :permission, presence: true
      end
    end
  end
end
