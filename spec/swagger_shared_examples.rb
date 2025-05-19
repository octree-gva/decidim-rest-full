# frozen_string_literal: true

RSpec.shared_examples "paginated endpoint" do
  parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
  parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
end

RSpec.shared_examples "localized endpoint" do
  parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Decidim::RestFull::DefinitionRegistry.schema_for(:locales), required: false
end

RSpec.shared_examples "resource endpoint" do
  parameter name: "space_manifest", in: :query, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }, required: false
  parameter name: "space_id", in: :query, schema: { type: :integer, description: "Space Id" }, required: false
  parameter name: "component_id", in: :query, schema: { type: :integer, description: "Component Id" }, required: false
end

RSpec.shared_examples "filtered endpoint" do |options = {}|
  filter = options[:filter]
  item_schema = options[:item_schema]
  filter_group = options[:only]
  filter_groups = {
    integer: %w(not_in not_eq start not_start matches does_not_match blank),
    string: %w(lt gt not_start does_not_match present)
  }
  raise "exclude must be one of #{filter_groups.keys}" unless filter_groups.has_key?(filter_group)

  exclude_filters = filter_groups[filter_group]

  filters_attributes = [
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
        **item_schema,
        title: "#{filter} equal filter",
        description: "_#{filter}_ is equal to"
      }, required: false
    },
    {
      name: "filter[#{filter}_not_eq]", in: :query, schema: {
        **item_schema,
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
      **item_schema,
      title: "#{filter} less than filter",
      description: "_#{filter}_ is less than"
    }, required: false },
    {
      name: "filter[#{filter}_gt]", in: :query, schema: {
        **item_schema,
        title: "#{filter} greater than filter",
        description: "_#{filter}_ is greater than"
      }, required: false
    },
    {
      name: "filter[#{filter}_present]", in: :query, schema: {
        type: :boolean,
        title: "#{filter} present filter",
        description: "_#{filter}_ is not null and not empty"
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

  filters_attributes.each do |param_attributes|
    parameter(**param_attributes)
  end
end
