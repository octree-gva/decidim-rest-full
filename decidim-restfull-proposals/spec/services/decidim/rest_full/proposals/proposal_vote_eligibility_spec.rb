# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::RestFull::Proposals::ProposalVoteEligibility do
  let(:organization) { create(:organization, available_locales: %w(en)) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:step_id) { participatory_process.active_step.id }

  describe ".voting_enabled?" do
    it "is true when votes_enabled and not blocked" do
      component = create(
        :proposal_component,
        participatory_space: participatory_process,
        step_settings: { step_id => { votes_enabled: true, votes_blocked: false } }
      )
      expect(described_class.voting_enabled?(component)).to be(true)
    end

    it "is false when votes_blocked" do
      component = create(
        :proposal_component,
        participatory_space: participatory_process,
        step_settings: { step_id => { votes_enabled: true, votes_blocked: true } }
      )
      expect(described_class.voting_enabled?(component)).to be(false)
    end
  end

  describe ".proposal_can_vote?" do
    context "when status filter is off" do
      let(:component) do
        create(
          :proposal_component,
          participatory_space: participatory_process,
          step_settings: { step_id => { votes_enabled: true } }
        )
      end

      it "is true for accepted proposals" do
        proposal = create(:proposal, :accepted, component:)
        expect(described_class.proposal_can_vote?(proposal)).to be(true)
      end

      it "is false for rejected proposals" do
        proposal = create(:proposal, :rejected, component:)
        expect(described_class.proposal_can_vote?(proposal)).to be(false)
      end

      it "is false when voting is disabled" do
        disabled = create(
          :proposal_component,
          participatory_space: participatory_process,
          step_settings: { step_id => { votes_enabled: false } }
        )
        proposal = create(:proposal, :accepted, component: disabled)
        expect(described_class.proposal_can_vote?(proposal)).to be(false)
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

      it "is true only for allowed statuses" do
        accepted = create(:proposal, :accepted, component:)
        evaluating = create(:proposal, :evaluating, component:)
        expect(described_class.proposal_can_vote?(accepted)).to be(true)
        expect(described_class.proposal_can_vote?(evaluating)).to be(false)
      end
    end
  end

  describe ".unvoted_voteable_proposals_exist?" do
    let(:user) { create(:user, organization:, confirmed_at: Time.zone.now) }

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

      it "ignores proposals outside allowed statuses" do
        create(:proposal, :evaluating, component:)
        expect(described_class.unvoted_voteable_proposals_exist?(component, user)).to be(false)

        create(:proposal, :accepted, component:)
        expect(described_class.unvoted_voteable_proposals_exist?(component, user)).to be(true)
      end
    end
  end
end
