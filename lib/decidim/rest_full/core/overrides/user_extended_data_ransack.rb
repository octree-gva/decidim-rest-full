# frozen_string_literal: true

module Decidim
  module RestFull
    module UserExtendedDataRansack
      extend ActiveSupport::Concern

      included do
        ransacker :extended_data do |_parent|
          Arel.sql(%{("decidim_users"."extended_data")::text})
        end
      end
    end
  end
end
