# frozen_string_literal: true

RSpec.shared_examples "paginated params" do
  parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
  parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
end

RSpec.shared_examples "ordered params" do |options = {}|
  columns = options[:columns]
  order_parameter_attributes = {
    name: :order,
    in: :query,
    schema: { type: :string },
    description: "Order by",
    required: false
  }
  order_parameter_attributes[:schema][:enum] = columns if columns.present?
  parameter order_parameter_attributes
  parameter name: :order_direction, in: :query, schema: { type: :string, enum: %w(asc desc) }, description: "Order direction", required: false
end

RSpec.shared_examples "ordered endpoint" do |options = {}|
  columns = options[:columns]
  break if columns.blank?

  columns.each do |column|
    context "when ordered by #{column}" do
      before do
        resources.each(&:destroy)
        Array.new(3) { create_resource.call }.each_with_index do |resource, index|
          each_resource.call(resource, index)
          resource.reload
        end
        resources.reload if resources.respond_to?(:reload)
      end

      context "when order_direction=asc" do
        let(:order) { column }
        let(:order_direction) { "asc" }

        run_test! do |example|
          data = JSON.parse(example.body)["data"]
          resources_ids = resources.order(column => :asc).ids
          expect(data.first["id"]).to eq(resources_ids.first.to_s)
          expect(data.last["id"]).to eq(resources_ids.last.to_s)
        end
      end

      context "when order_direction=desc" do
        let(:order) { column }
        let(:order_direction) { "desc" }

        run_test! do |example|
          data = JSON.parse(example.body)["data"]
          resources_ids = resources.order(column => :desc).ids
          expect(data.first["id"]).to eq(resources_ids.first.to_s)
          expect(data.last["id"]).to eq(resources_ids.last.to_s)
        end
      end
    end
  end
end

RSpec.shared_examples "paginated endpoint" do |options = {}|
  sample_size = options.fetch(:sample_size, 3)

  raise ArgumentError, "sample_size must be less than 100" unless sample_size < 100

  let(:destroy_resources) { -> { resources.each(&:destroy!) } }
  before do
    destroy_resources.call
    resources.reload if resources.respond_to?(:reload)
  end

  context "with no resources, return empty array" do
    let(:per_page) { 2 }
    let(:page) { 1 }

    run_test! do |example|
      json_response = JSON.parse(example.body)
      expect(json_response["data"].size).to eq(0)
    end
  end

  context "with #{sample_size} resources" do
    before do
      Array.new(sample_size) { create_resource.call }.each_with_index do |resource, index|
        each_resource.call(resource, index)
      end
      resources.reload if resources.respond_to?(:reload)
    end

    context "when per_page=2 and page=1, list 2 resources" do
      let(:per_page) { 2 }
      let(:page) { 1 }

      run_test!(example_name: :paginated) do |example|
        json_response = JSON.parse(example.body)
        expect(json_response["data"].size).to eq(2)
      end
    end

    context "when per_page=2 and page=#{((sample_size + 1) / 2).ceil}, list #{sample_size % 2} resource" do
      let(:per_page) { 2 }
      let(:page) { ((sample_size + 1) / 2).ceil }

      run_test! do |example|
        json_response = JSON.parse(example.body)
        expect(json_response["data"].size).to eq(sample_size % 2)
      end
    end

    context "when per_page=1 and page=100, return empty array" do
      let(:per_page) { 1 }
      let(:page) { 100 }

      run_test! do |example|
        json_response = JSON.parse(example.body)
        expect(json_response["data"]).to be_empty
      end
    end
  end
end

RSpec.shared_examples "localized endpoint" do
  response "400", "Bad Request" do
    consumes "application/json"
    produces "application/json"
    schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

    context "with invalid locales[] fields" do
      let(:"locales[]") { ["invalid_locale"] }

      run_test! do |example|
        error_description = JSON.parse(example.body)["error_description"]
        expect(error_description).to start_with("Not allowed locales:")
      end
    end
  end
end

RSpec.shared_examples "localized params" do
  parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Decidim::RestFull::DefinitionRegistry.schema_for(:locales), required: false
end

RSpec.shared_examples "resource params" do
  parameter name: "space_manifest", in: :query, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }, required: false
  parameter name: "space_id", in: :query, schema: { type: :integer, description: "Space Id" }, required: false
  parameter name: "component_id", in: :query, schema: { type: :integer, description: "Component Id" }, required: false
end

RSpec.shared_examples "filtered params" do |options = {}|
  filter = options[:filter]
  item_schema = options[:item_schema]
  filter_group = options[:only]
  filter_groups = {
    integer: %w(not_in not_eq start not_start matches does_not_match),
    string: %w(lt gt not_start does_not_match present)
  }
  security = options[:security]
  additional_description = security ? ". Only available with #{security} flow" : ""
  raise "exclude must be one of #{filter_groups.keys}" unless filter_groups.has_key?(filter_group)

  exclude_filters = filter_groups[filter_group]

  filters_attributes = [
    {
      name: "filter[#{filter}_not_in][]", in: :query, style: :form, explode: true, schema: {
        type: :array,
        items: item_schema,
        title: "#{filter} not IN filter",
        description: "match none of _#{filter}_'s values in array#{additional_description}"
      }, required: false
    },
    {
      name: "filter[#{filter}_in][]", in: :query, style: :form, explode: true, schema: {
        type: :array,
        items: item_schema,
        title: "#{filter} IN filter",
        description: "match one of _#{filter}_'s values in array#{additional_description}"
      }, required: false
    },
    {
      name: "filter[#{filter}_start]", in: :query, schema: {
        type: :string,
        description: "_#{filter}_ starts with#{additional_description}",
        title: "#{filter} starts With filter",
        example: "some_string"
      }, required: false
    }, {
      name: "filter[#{filter}_not_start]", in: :query, schema: {
        type: :string,
        description: "_#{filter}_ does not starts with#{additional_description}",
        title: "#{filter} not starts With filter",
        example: "some_string"
      }, required: false
    },
    {
      name: "filter[#{filter}_eq]", in: :query, schema: {
        **item_schema,
        title: "#{filter} equal filter",
        description: "_#{filter}_ is equal to#{additional_description}"
      }, required: false
    },
    {
      name: "filter[#{filter}_not_eq]", in: :query, schema: {
        **item_schema,
        title: "#{filter} not equal filter",
        description: "_#{filter}_ is NOT equal to#{additional_description}"
      }, required: false
    },
    {
      name: "filter[#{filter}_matches]", in: :query, schema: {
        type: :string,
        title: "#{filter} like filter",
        description: "matches _#{filter}_ with `LIKE`#{additional_description}",
        example: "%some_string"
      }, required: false
    },
    {
      name: "filter[#{filter}_does_not_match]", in: :query, schema: {
        type: :string,
        title: "#{filter} not like filter",
        description: "Does not matches _#{filter}_ with `LIKE`#{additional_description}"
      }, required: false
    },
    { name: "filter[#{filter}_lt]", in: :query, schema: {
      **item_schema,
      title: "#{filter} less than filter",
      description: "_#{filter}_ is less than#{additional_description}"
    }, required: false },
    {
      name: "filter[#{filter}_gt]", in: :query, schema: {
        **item_schema,
        title: "#{filter} greater than filter",
        description: "_#{filter}_ is greater than#{additional_description}"
      }, required: false
    },
    {
      name: "filter[#{filter}_present]", in: :query, schema: {
        type: :boolean,
        title: "#{filter} present filter",
        description: "_#{filter}_ is not null and not empty#{additional_description}"
      }, required: false
    },
    {
      name: "filter[#{filter}_blank]", in: :query, schema: {
        type: :boolean,
        title: "#{filter} blank filter",
        description: "_#{filter}_ is null or empty#{additional_description}"
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
