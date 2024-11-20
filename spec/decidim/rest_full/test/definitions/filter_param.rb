# frozen_string_literal: true

module Api
  module Definitions
    FILTER_PARAM = lambda do |filter, item_schema = { type: :string }|
      [{
        name: "filter[#{filter}_not_in][]", in: :query, style: :form, explode: true, schema: {
          type: :array,
          items: item_schema,
          description: "match none of values in array"
        }, required: false
      }, {
        name: "filter[#{filter}_in][]", in: :query, style: :form, explode: true, schema: {
          type: :array,
          items: item_schema,
          description: "match one of values in array"
        }, required: false
      },
       {
         name: "filter[#{filter}_start]", in: :query, schema: {
           type: :string,
           description: "Starts with"
         }, required: false
       }, {
         name: "filter[#{filter}_not_start]", in: :query, schema: {
           type: :string,
           description: "Does not starts with"
         }, required: false
       },
       {
         name: "filter[#{filter}_eq]", in: :query, schema: {
           type: :string,
           description: "Equal #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_not_eq]", in: :query, schema: {
           type: :string,
           description: "Not Equal #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_matches]", in: :query, schema: {
           type: :string,
           description: "matches with `LIKE` #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_does_not_match]", in: :query, schema: {
           type: :string,
           description: "Does not matches with `LIKE` #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_matches_any]", in: :query, schema: {
           type: :string,
           description: "Match any with `LIKE` #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_matches_all]", in: :query, schema: {
           type: :string,
           description: "Match any with `LIKE` #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_does_not_match_any]", in: :query, schema: {
           type: :string,
           description: "Does not match any with `LIKE` #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_does_not_match_all]", in: :query, schema: {
           type: :string,
           description: "Does not match all with `LIKE` #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_lt]", in: :query, schema: {
           type: :string,
           description: "Less than #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_lteq]", in: :query, schema: {
           type: :string,
           description: "less than or equal #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_gt]", in: :query, schema: {
           type: :string,
           description: "greater than #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_gteq]", in: :query, schema: {
           type: :string,
           description: "greater than or equal #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_present]", in: :query, schema: {
           type: :string,
           description: "not null and not empty #{filter}"
         }, required: false
       },
       {
         name: "filter[#{filter}_blank]", in: :query, schema: {
           type: :string,
           description: "is null or empty. #{filter}"
         }, required: false
       }]
    end
  end
end
