# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::SerializerAdditionsRegistry do
  let(:widget_serializer) do
    Class.new(Decidim::Api::RestFull::Core::ApplicationSerializer) do
      set_type :widget
    end
  end

  let(:item_serializer) do
    Class.new(Decidim::Api::RestFull::Core::ApplicationSerializer) do
      set_type :item

      meta do |_record, _params|
        { base_meta: true }
      end
    end
  end

  before do
    Decidim::RestFull::Core::SerializerAdditionsRegistry.reset!
    Decidim::RestFull::Core::HttpCache::FingerprintContributorRegistry.reset!
    stub_const("RestFullSpec::WidgetSerializer", widget_serializer)
    stub_const("RestFullSpec::ItemSerializer", item_serializer)
  end

  def build_registration(extension_name:, serializer_name:, &block)
    builder = Decidim::RestFull::Core::RestEnhancementBuilder.new(
      extension_name:,
      serializer_name:,
      http_cache_profile: nil
    )
    builder.instance_eval(&block) if block
    builder.validate_http_cache_strictness!
    builder.to_registration
  end

  describe ".register" do
    it "raises when two extensions declare the same relationship name" do
      described_class.reset!
      described_class.register(
        build_registration(extension_name: :a, serializer_name: "RestFullSpec::ItemSerializer") do
          has_many(:widgets, serializer: RestFullSpec::WidgetSerializer) { |_r, _p| [] }
        end
      )

      expect do
        described_class.register(
          build_registration(extension_name: :b, serializer_name: "RestFullSpec::ItemSerializer") do
            has_many(:widgets, serializer: RestFullSpec::WidgetSerializer) { |_r, _p| [] }
          end
        )
      end.to raise_error(ArgumentError, /relationship conflict/)
    end
  end

  describe ".apply!" do
    it "does not raise when the serializer constant is not yet defined" do
      described_class.reset!
      described_class.register(
        build_registration(extension_name: :ghost, serializer_name: "RestFullSpec::NoSuchSerializer") do
          meta { { ghost: true } }
        end
      )

      expect { described_class.apply! }.not_to raise_error
    end

    it "applies has_many once and stays idempotent across repeated apply!" do
      described_class.reset!
      described_class.register(
        build_registration(extension_name: :demo, serializer_name: "RestFullSpec::ItemSerializer") do
          has_many(:widgets, serializer: RestFullSpec::WidgetSerializer) { |_r, _p| [] }
        end
      )

      2.times { described_class.apply! }

      rel = RestFullSpec::ItemSerializer.relationships_to_serialize[:widgets]
      expect(rel).to be_present
    end

    it "merges meta without clobbering the base serializer meta" do
      described_class.reset!
      described_class.register(
        build_registration(extension_name: :demo, serializer_name: "RestFullSpec::ItemSerializer") do
          meta { |_record, _params| { addon: 1 } }
        end
      )

      described_class.apply!

      item = Struct.new(:id).new(1)
      hash = RestFullSpec::ItemSerializer.new(item, params: {}).serializable_hash
      expect(hash[:data][:meta]).to include(base_meta: true, addon: 1)
    end
  end
end
