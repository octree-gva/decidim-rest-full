# frozen_string_literal: true

# rubocop:disable RSpec/SpecFilePathFormat, RSpec/DescribeMethod -- descriptive scenario title alongside serializer class
require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Proposals::ProposalComponentSerializer,
               "participatory process phases (PROPOSE vs VOTE)" do
  let(:organization) { create(:organization, available_locales: %w(en)) }
  let(:meta) { serialize.fetch(:data).fetch(:meta).symbolize_keys }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let!(:propose_phase) { create(:participatory_process_step, :active, participatory_process:, position: 0) }
  let!(:vote_phase) { create(:participatory_process_step, active: false, participatory_process:, position: 1) }
  let(:user) { create(:user, organization:, confirmed_at: Time.zone.now) }
  let(:api_client) { create(:api_client, organization:, scopes: ["public"]) }

  let!(:proposal_component) do
    create(
      :proposal_component,
      participatory_space: participatory_process,
      step_settings: {
        propose_phase.id.to_s => { creation_enabled: true, votes_enabled: false },
        vote_phase.id.to_s => { creation_enabled: false, votes_enabled: true }
      },
      settings: { awesome_voting_manifest: :voting_cards }
    )
  end

  def serialize(component = proposal_component.reload)
    described_class.new(
      component,
      params: {
        only: [],
        locales: %w(en),
        host: organization.host,
        act_as: user,
        client_id: api_client.id
      }
    ).serializable_hash
  end

  describe "Scenario 1: active phase PROPOSE (no voting on step)" do
    it "sets can_vote false and creation true" do
      expect(meta[:votes_enabled]).to be(false)
      expect(meta[:can_vote]).to be(false)
      expect(meta[:creation_enabled]).to be(true)
      expect(meta[:can_create_proposals]).to be(true)
    end
  end

  describe "Scenario 2: active phase VOTE; participant still has proposals to vote on" do
    let!(:proposal) { create(:proposal, :accepted, component: proposal_component) }

    before do
      propose_phase.update!(active: false)
      vote_phase.update!(active: true)
      participatory_process.reload
      proposal_component.reload
    end

    it "sets can_vote true" do
      expect(meta[:votes_enabled]).to be(true)
      expect(meta[:creation_enabled]).to be(false)
      expect(meta[:can_create_proposals]).to be(false)
      expect(meta[:can_vote]).to be(true)
    end
  end

  describe "Scenario 3: active phase VOTE; participant has voted on all voteable proposals" do
    let!(:proposal) { create(:proposal, :accepted, component: proposal_component) }

    before do
      create(:proposal_vote, proposal:, author: user)
      propose_phase.update!(active: false)
      vote_phase.update!(active: true)
      participatory_process.reload
      proposal_component.reload
    end

    it "sets can_vote false" do
      expect(meta[:votes_enabled]).to be(true)
      expect(meta[:can_vote]).to be(false)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat, RSpec/DescribeMethod
