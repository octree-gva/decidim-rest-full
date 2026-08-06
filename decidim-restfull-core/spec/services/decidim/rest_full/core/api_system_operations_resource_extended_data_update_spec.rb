# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::ApiSystemOperations, "#resource_extended_data_update!" do
  subject(:ops) { described_class.new(ctx, params) }

  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:component) { create(:component, participatory_space: participatory_process) }
  let(:ctx) { Decidim::RestFull::ApiExecutionContext.new(organization:, doorkeeper_token: nil) }
  let(:params) do
    ActionController::Parameters.new(
      resource_type: component.class.name,
      resource_id: component.id,
      object_path: ".",
      data: { "big" => "x" * 100 }
    )
  end

  it "rejects oversized sync payloads when capped" do
    allow(Decidim::RestFull.config).to receive(:max_extended_data_payload_bytes).and_return(32)

    expect do
      ops.resource_extended_data_update!
    end.to raise_error(Decidim::RestFull::Core::ApiException::BadRequest, /exceeds maximum size/)
  end

  it "accepts payloads under the cap" do
    allow(Decidim::RestFull.config).to receive(:max_extended_data_payload_bytes).and_return(10_000)

    result = ops.resource_extended_data_update!
    expect(result[:data]).to include("big")
  end
end
