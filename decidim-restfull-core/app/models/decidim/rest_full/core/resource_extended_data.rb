# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Satellite row for client metadata on any resource that includes HasExtendedData
      # (same idea as Decidim::Forms::Questionnaire / Decidim::ResourcePermission).
      class ResourceExtendedData < ::ApplicationRecord
        self.table_name = "resource_extended_data"

        # Bump parent updated_at so ResourceShowFingerprint / collection ETags invalidate.
        belongs_to :resource, polymorphic: true, touch: true
      end
    end
  end
end
