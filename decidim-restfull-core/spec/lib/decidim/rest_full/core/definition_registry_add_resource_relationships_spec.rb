# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::DefinitionRegistry do
  describe ".add_resource_relationships" do
    it "raises when the resource schema is missing" do
      expect do
        described_class.add_resource_relationships(:missing_resource, foo: { type: :object })
      end.to raise_error(ArgumentError, /not registered/)
    end

    it "raises when the relationship key already exists" do
      expect do
        described_class.add_resource_relationships(:proposal, state: { type: :object })
      end.to raise_error(ArgumentError, /already exists/)
    end
  end
end
