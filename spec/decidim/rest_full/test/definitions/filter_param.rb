# frozen_string_literal: true

module Api
  module Definitions
    FILTER_PARAM = lambda do |filter, item_schema = { type: :string }, exclude_filters = []|
      [
        {
          name: "filter[#{filter}_not_in][]", in: :query, style: :form, explode: true, schema: {
            type: :array,
            items: item_schema,
            title: "#{filter} not IN filter",
            description: "match none of _#{filter}_'s values in array"
          }, required: false
        },
        {
          name: "filter[#{filter}_in][]", in: :query, style: :form, explode: true, schema: {
            type: :array,
            items: item_schema,
            title: "#{filter} IN filter",
            description: "match one of _#{filter}_'s values in array"
          }, required: false
        },
        {
          name: "filter[#{filter}_start]", in: :query, schema: {
            type: :string,
            description: "_#{filter}_ starts with",
            title: "#{filter} starts With filter",
            example: "some_string"
          }, required: false
        }, {
          name: "filter[#{filter}_not_start]", in: :query, schema: {
            type: :string,
            description: "_#{filter}_ does not starts with",
            title: "#{filter} not starts With filter",
            example: "some_string"
          }, required: false
        },
        {
          name: "filter[#{filter}_eq]", in: :query, schema: {
            type: :string,
            title: "#{filter} equal filter",
            description: "_#{filter}_ is equal to"
          }, required: false
        },
        {
          name: "filter[#{filter}_not_eq]", in: :query, schema: {
            type: :string,
            title: "#{filter} not equal filter",
            description: "_#{filter}_ is NOT equal to"
          }, required: false
        },
        {
          name: "filter[#{filter}_matches]", in: :query, schema: {
            type: :string,
            title: "#{filter} like filter",
            description: "matches _#{filter}_ with `LIKE`",
            example: "%some_string"
          }, required: false
        },
        {
          name: "filter[#{filter}_does_not_match]", in: :query, schema: {
            type: :string,
            title: "#{filter} not like filter",
            description: "Does not matches _#{filter}_ with `LIKE`"
          }, required: false
        },
        { name: "filter[#{filter}_lt]", in: :query, schema: {
          type: :string,
          title: "#{filter} less than filter",
          description: "_#{filter}_ is less than"
        }, required: false },
        {
          name: "filter[#{filter}_gt]", in: :query, schema: {
            type: :string,
            title: "#{filter} greater than filter",
            description: "_#{filter}_ is greater than"
          }, required: false
        },
        {
          name: "filter[#{filter}_present]", in: :query, schema: {
            type: :string,
            title: "#{filter} present filter",
            description: "_#{filter}_ is not null and not empty",
            enum: %w(1 0),
            example: "1"
          }, required: false
        },
        {
          name: "filter[#{filter}_blank]", in: :query, schema: {
            type: :boolean,
            title: "#{filter} blank filter",
            description: "_#{filter}_ is null or empty"
          }, required: false
        }
      ].reject do |filter_param|
        name = filter_param[:name]
        excluded = exclude_filters.map do |suffix|
          [
            "filter[#{filter}_#{suffix}]",
            "filter[#{filter}_#{suffix}][]"
          ]
        end.flatten
        excluded.include?(name)
      end
    end
  end
end
