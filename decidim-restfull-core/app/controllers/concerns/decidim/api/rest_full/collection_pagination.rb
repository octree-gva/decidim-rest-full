# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      # Offset pagination for collection/index responses (limit+1, no COUNT).
      # Returns [records, meta] with page, per_page, has_more, next, prev.
      #
      # When sorting with +rand+ / +RANDOM()+, page offsets are not stable across
      # requests, so +has_more+ is always +true+ (clients should stop when a page
      # returns fewer than +per_page+ rows if they need a finite walk).
      module CollectionPagination
        extend ActiveSupport::Concern

        DEFAULT_PER_PAGE = 20
        MAX_PER_PAGE = 100

        private

        # @param scope [ActiveRecord::Relation, Enumerable]
        # @return [Array(Array, Hash)] records and pagination meta
        def paginate_collection(scope)
          page = normalize_collection_page(params[:page])
          per = normalize_collection_per_page(params[:per_page])
          fetch_limit = per + 1
          offset = (page - 1) * per

          rows = if scope.is_a?(ActiveRecord::Relation)
                   scope.offset(offset).limit(fetch_limit).to_a
                 else
                   Array(scope).slice(offset, fetch_limit) || []
                 end

          overflow = rows.size > per
          records = overflow ? rows.first(per) : rows
          # RANDOM() order is not stable across pages — never claim a last page.
          has_more = random_collection_order? || overflow

          meta = {
            page:,
            per_page: per,
            has_more:,
            next: has_more ? collection_page_url(page + 1, per) : nil,
            prev: page > 1 ? collection_page_url(page - 1, per) : nil
          }
          [records, meta]
        end

        def random_collection_order?
          explicit = params[:order].presence
          explicit = default_order_column if explicit.blank? && respond_to?(:default_order_column, true)
          explicit.to_s == "rand"
        end

        def normalize_collection_page(raw)
          value = Integer(raw, exception: false)
          return 1 if value.nil? || value < 1

          value
        end

        def normalize_collection_per_page(raw)
          value = Integer(raw, exception: false)
          return DEFAULT_PER_PAGE if value.nil? || value < 1

          [value, MAX_PER_PAGE].min
        end

        def collection_page_url(page, per_page)
          query = request.query_parameters.merge("page" => page, "per_page" => per_page)
          query_string = query.to_query
          base = "#{request.base_url}#{request.path}"
          query_string.present? ? "#{base}?#{query_string}" : base
        end
      end
    end
  end
end
