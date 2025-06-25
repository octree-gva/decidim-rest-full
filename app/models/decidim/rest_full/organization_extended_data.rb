# frozen_string_literal: true

module Decidim
  module RestFull
    class OrganizationExtendedData < ApplicationRecord
      self.table_name = "organization_extended_data"
      belongs_to :organization, class_name: "Decidim::Organization"
    end
  end
end
