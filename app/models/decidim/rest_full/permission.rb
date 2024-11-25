# frozen_string_literal: true

module Decidim
  module RestFull
    class Permission < ::ApplicationRecord
      self.table_name = "decidim_rest_full_api_client_permissions"

      belongs_to :api_client, class_name: "Decidim::RestFull::ApiClient"

      validates :permission, presence: true
    end
  end
end
