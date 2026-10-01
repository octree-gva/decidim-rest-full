# frozen_string_literal: true

# rubocop:disable RSpec/SpecFilePathFormat, RSpec/DescribeMethod -- descriptive scenario title alongside serializer class
require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Proposals::ProposalSerializer, "meta.can_vote" do
  subject(:serialized) do
    described_class.new(
      proposal,
      params: {
        only: [],
        locales: %w(en),
        host: organization.host,
        act_as: nil,
        client_id: api_client.id
      }
    ).serializable_hash
  end

  let(:organization) { create(:organization, available_locales: %w(en)) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:step_id) { participatory_process.active_step.id }
  let(:api_client) { create(:api_client, organization:, scopes: ["public"]) }
  let(:meta) { serialized.fetch(:data).fetch(:meta).symbolize_keys }

  let(:component) do
    create(
      :proposal_component,
      participatory_space: participatory_process,
      step_settings: { step_id => { votes_enabled: true } }
    )
  end

  context "when status filter is off" do
    let(:proposal) { create(:proposal, :accepted, component:) }

    it "sets can_vote true for non-rejected proposals" do
      expect(meta[:can_vote]).to be(true)
    end

    context "with a rejected proposal" do
      let(:proposal) { create(:proposal, :rejected, component:) }

      it "sets can_vote false" do
        expect(meta[:can_vote]).to be(false)
      end
    end
  end

  context "when status filter is on", if: (
    Decidim::Toggle.gem_present?("decidim-decidim_awesome") &&
    defined?(Decidim::DecidimAwesome) &&
    Decidim::DecidimAwesome.enabled?(:votes_by_proposal_status)
  ) do
    let(:component) do
      create(
        :proposal_component,
        participatory_space: participatory_process,
        step_settings: {
          step_id => {
            votes_enabled: true,
            awesome_votes_enabled_by_status: true,
            awesome_votes_enabled_states: %w(accepted)
          }
        }
      )
    end

    context "with an allowed status" do
      let(:proposal) { create(:proposal, :accepted, component:) }

      it "sets can_vote true" do
        expect(meta[:can_vote]).to be(true)
      end
    end

    context "with a disallowed status" do
      let(:proposal) { create(:proposal, :evaluating, component:) }

      it "sets can_vote false" do
        expect(meta[:can_vote]).to be(false)
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat, RSpec/DescribeMethod
