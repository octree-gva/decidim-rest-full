# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      # MIN/MAX/COUNT for collection navigation meta without loading all primary keys.
      module CollectionPaginationMeta
        extend ActiveSupport::Concern

        private

        def collection_pagination_bounds(relation_scope)
          table_name = model_class.table_name
          base = relation_scope.except(:select, :order, :limit, :offset, :reorder)
          row = base.pick(
            Arel.sql("MIN(#{table_name}.id)"),
            Arel.sql("MAX(#{table_name}.id)"),
            Arel.sql("COUNT(#{table_name}.id)")
          )
          { first: row&.first, last: row&.second, count: row&.third.to_i }
        end
      end
    end
  end
end
