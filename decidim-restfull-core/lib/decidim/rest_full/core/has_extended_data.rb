# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module RestFull
    module Core
      # Attach API client metadata in a related table (see HasQuestionnaire / HasResourcePermission).
      module HasExtendedData
        extend ActiveSupport::Concern

        included do
          has_one :extended_data,
                  class_name: "Decidim::RestFull::Core::ResourceExtendedData",
                  dependent: :destroy,
                  inverse_of: :resource,
                  as: :resource

          after_create :ensure_extended_data

          register_extended_data_ransacker!
        end

        def extended_data_hash
          extended_data&.data || {}
        end

        private

        def ensure_extended_data
          return unless ActiveRecord::Base.connection.table_exists?(:resource_extended_data)
          return if extended_data

          create_extended_data!
        end

        class_methods do
          def register_extended_data_ransacker!
            return if singleton_class.method_defined?(:rest_full_extended_data_ransacker_defined)

            begin
              conn = connection
              quoted_type = conn.quote(name)
              resource_id_sql = "#{conn.quote_table_name(table_name)}.#{conn.quote_column_name("id")}"
            # ponytail: no-op when DB missing (db:create / early boot before migrate)
            rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
              return
            rescue StandardError => e
              raise unless defined?(PG::ConnectionBad) && e.is_a?(PG::ConnectionBad)

              return
            end

            ransacker :extended_data do |_parent|
              Arel.sql(<<~SQL.squish)
                (SELECT data::text FROM resource_extended_data
                 WHERE resource_type = #{quoted_type}
                   AND resource_id = #{resource_id_sql})
              SQL
            end

            Decidim::RestFull::Core::Ransackers.extend_ransackable_attributes!(self, %w(extended_data))

            define_singleton_method(:rest_full_extended_data_ransacker_defined) { true }
          end
        end
      end
    end
  end
end
