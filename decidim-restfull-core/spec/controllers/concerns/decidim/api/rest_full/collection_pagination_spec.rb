# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Api
    module RestFull
      RSpec.describe CollectionPagination do
        let(:host) do
          Class.new do
            include CollectionPagination

            attr_accessor :params, :request

            def initialize(params:, request:)
              @params = params
              @request = request
            end
          end
        end

        def build_request(path: "/api/rest_full/v0.3/widgets", query: {})
          req = ActionDispatch::TestRequest.create
          req.path = path
          req.host = "example.org"
          req.query_parameters.replace(query.stringify_keys)
          req
        end

        def paginate(scope, page: nil, per_page: nil, query: {})
          params = query.merge({ page:, per_page: }.compact)
          request = build_request(query: params)
          instance = host.new(
            params: ActionController::Parameters.new(params),
            request:
          )
          instance.send(:paginate_collection, scope)
        end

        it "defaults page to 1 and per_page to 20" do
          records, meta = paginate((1..25).to_a)
          expect(records.size).to eq(20)
          expect(meta[:page]).to eq(1)
          expect(meta[:per_page]).to eq(20)
          expect(meta[:has_more]).to be(true)
          expect(meta[:next]).to include("page=2")
          expect(meta[:next]).to include("per_page=20")
          expect(meta[:prev]).to be_nil
        end

        it "clamps per_page above 100 to 100" do
          _records, meta = paginate((1..5).to_a, per_page: 200)
          expect(meta[:per_page]).to eq(100)
        end

        it "falls back invalid per_page and page" do
          _records, meta = paginate((1..5).to_a, page: 0, per_page: -3)
          expect(meta[:page]).to eq(1)
          expect(meta[:per_page]).to eq(20)
        end

        it "sets has_more false on last page and builds prev" do
          records, meta = paginate((1..5).to_a, page: 2, per_page: 3)
          expect(records).to eq([4, 5])
          expect(meta[:has_more]).to be(false)
          expect(meta[:next]).to be_nil
          expect(meta[:prev]).to include("page=1")
        end

        it "preserves filter query params in next/prev" do
          _records, meta = paginate(
            (1..5).to_a,
            page: 1,
            per_page: 2,
            query: { "filter" => { "state_eq" => "accepted" }, "order" => "published_at" }
          )
          expect(meta[:next]).to include("filter")
          expect(meta[:next]).to include("state_eq")
          expect(meta[:next]).to include("order=published_at")
        end

        it "paginates ActiveRecord::Relation with limit+1" do
          relation = instance_double(ActiveRecord::Relation)
          limited = instance_double(ActiveRecord::Relation)
          allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
          allow(relation).to receive(:offset).with(0).and_return(relation)
          allow(relation).to receive(:limit).with(3).and_return(limited)
          allow(limited).to receive(:to_a).and_return([1, 2, 3])

          records, meta = paginate(relation, page: 1, per_page: 2)
          expect(records).to eq([1, 2])
          expect(meta[:has_more]).to be(true)
        end

        it "always sets has_more true when order is rand" do
          records, meta = paginate((1..2).to_a, page: 2, per_page: 1, query: { "order" => "rand" })
          expect(records).to eq([2])
          expect(meta[:has_more]).to be(true)
          expect(meta[:next]).to include("page=3")
          expect(meta[:next]).to include("order=rand")
        end

        it "treats blank order as rand when default_order_column is rand" do
          host_with_default = Class.new do
            include CollectionPagination

            attr_accessor :params, :request

            def initialize(params:, request:)
              @params = params
              @request = request
            end

            def default_order_column
              "rand"
            end
          end

          params = ActionController::Parameters.new(page: 1, per_page: 10)
          request = build_request(query: { "page" => 1, "per_page" => 10 })
          instance = host_with_default.new(params:, request:)
          _records, meta = instance.send(:paginate_collection, (1..3).to_a)
          expect(meta[:has_more]).to be(true)
        end
      end
    end
  end
end
