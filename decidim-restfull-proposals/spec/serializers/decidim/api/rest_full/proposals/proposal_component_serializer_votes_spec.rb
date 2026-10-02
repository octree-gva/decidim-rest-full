# frozen_string_literal: true

# rubocop:disable RSpec/SpecFilePathFormat, RSpec/DescribeMethod -- descriptive scenario title alongside serializer class
require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Proposals::ProposalComponentSerializer, "meta.votes catalog" do
  let(:organization) { create(:organization, available_locales: %w(en)) }
  let(:meta) { serialize.fetch(:data).fetch(:meta).symbolize_keys }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:user) { create(:user, organization:, confirmed_at: Time.zone.now) }
  let(:api_client) { create(:api_client, organization:, scopes: ["public"]) }
  let(:component_settings) { {} }
  let(:votes_enabled) { true }

  let!(:proposal_component) do
    create(
      :proposal_component,
      participatory_space: participatory_process,
      settings: component_settings,
      step_settings: {
        participatory_process.steps.first.id.to_s => { votes_enabled:, creation_enabled: true }
      }
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

  def vote_weights
    meta.fetch(:votes).map { |option| option[:weight] || option["weight"] }
  end

  context "when votes are disabled" do
    let(:votes_enabled) { false }
    let(:component_settings) { { awesome_voting_manifest: :voting_cards, voting_cards_show_abstain: true } }

    it "returns an empty array, not nil" do
      expect(meta[:votes_enabled]).to be(false)
      expect(meta).to have_key(:votes)
      expect(meta[:votes]).to eq([])
    end
  end

  context "when simple vote without abstention" do
    let(:component_settings) { { voting_cards_show_abstain: false } }

    it "returns weight 1 only" do
      expect(vote_weights).to eq([1])
    end
  end

  context "when simple vote with abstention" do
    let(:component_settings) { { voting_cards_show_abstain: true } }

    it "returns weights 0 and 1" do
      expect(vote_weights).to eq([0, 1])
    end
  end

  context "when voting cards without abstention" do
    let(:component_settings) { { awesome_voting_manifest: :voting_cards, voting_cards_show_abstain: false } }

    it "returns weights 1, 2, 3" do
      expect(vote_weights).to eq([1, 2, 3])
      expect(meta[:awesome_voting_manifest].to_s).to eq("voting_cards")
      expect(meta[:voting_cards_show_abstain]).to be(false)
    end
  end

  context "when voting cards with abstention" do
    let(:component_settings) { { awesome_voting_manifest: :voting_cards, voting_cards_show_abstain: true } }

    it "returns weights 0, 1, 2, 3" do
      expect(vote_weights).to eq([0, 1, 2, 3])
      expect(meta[:voting_cards_show_abstain]).to be(true)
    end
  end

  context "when votes enabled but actor cannot vote anymore" do
    let(:component_settings) { { awesome_voting_manifest: :voting_cards, voting_cards_show_abstain: true } }
    let!(:proposal) { create(:proposal, :accepted, component: proposal_component) }

    before do
      create(:proposal_vote, proposal:, author: user)
    end

    it "keeps the vote catalog while can_vote is false" do
      expect(meta[:can_vote]).to be(false)
      expect(vote_weights).to eq([0, 1, 2, 3])
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat, RSpec/DescribeMethod
