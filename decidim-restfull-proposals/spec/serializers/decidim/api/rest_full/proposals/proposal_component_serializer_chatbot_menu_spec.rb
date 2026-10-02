# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Proposals::ProposalComponentSerializer do
  subject(:serialized) do
    described_class.new(
      proposal_component.reload,
      params: {
        only: [],
        locales: %w(en),
        host: organization.host,
        act_as: user,
        client_id: api_client.id
      }
    ).serializable_hash
  end

  let(:organization) { create(:organization, available_locales: %w(en)) }
  let(:data) { serialized.fetch(:data) }
  let(:meta) { data.fetch(:meta).symbolize_keys }
  let(:resource_count) do
    data.dig(:relationships, :resources, :meta, :count)
  end
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:user) { create(:user, organization:, confirmed_at: Time.zone.now) }
  let(:api_client) { create(:api_client, organization:, scopes: ["public"]) }

  describe "fields read by chat-platform when building proposal component menu buttons" do
    context "when participants can create proposals and voting is off" do
      let!(:proposal_component) do
        create(
          :proposal_component,
          :with_creation_enabled,
          participatory_space: participatory_process
        )
      end

      it "reports can_create_proposals, can_vote false, and zero resources" do
        expect(meta[:can_create_proposals]).to be(true)
        expect(meta[:can_vote]).to be(false)
        expect(resource_count).to eq(0)
      end

      context "with published proposals in the component" do
        before do
          create(:proposal, :accepted, component: proposal_component)
        end

        it "exposes non-zero published resource count" do
          expect(resource_count).to eq(1)
        end
      end
    end

    context "when participants can create and voting is enabled" do
      let!(:proposal_component) do
        step_id = participatory_process.active_step.id
        create(
          :proposal_component,
          participatory_space: participatory_process,
          step_settings: {
            step_id => { creation_enabled: true, votes_enabled: true }
          },
          settings: { awesome_voting_manifest: :voting_cards }
        )
      end

      it "reports votes phase on but can_vote false when there is nothing to vote (no pending unvoted proposals)" do
        expect(meta[:can_create_proposals]).to be(true)
        expect(meta[:can_vote]).to be(false)
        expect(resource_count).to eq(0)
      end

      context "with published proposals" do
        let!(:published_proposal) do
          create(:proposal, :accepted, component: proposal_component)
        end

        it "exposes positive resource count and can_vote while the user has unvoted proposals" do
          expect(resource_count).to eq(1)
          expect(meta[:can_vote]).to be(true)
        end

        it "exposes awesome status restriction keys" do
          expect(meta).to have_key(:awesome_votes_enabled_by_status)
          expect(meta).to have_key(:awesome_votes_enabled_states)
          expect(meta[:awesome_votes_enabled_by_status]).to be(false)
          expect(meta[:awesome_votes_enabled_states]).to eq([])
        end

        context "when the participant has voted on every voteable proposal" do
          before do
            create(:proposal_vote, proposal: published_proposal, author: user)
          end

          it "sets can_vote false" do
            expect(meta[:can_vote]).to be(false)
          end
        end
      end
    end

    context "when voting is restricted by proposal status", if: (
      Decidim::Toggle.gem_present?("decidim-decidim_awesome") &&
      defined?(Decidim::DecidimAwesome) &&
      Decidim::DecidimAwesome.enabled?(:votes_by_proposal_status)
    ) do
      let!(:proposal_component) do
        step_id = participatory_process.active_step.id
        create(
          :proposal_component,
          participatory_space: participatory_process,
          step_settings: {
            step_id => {
              creation_enabled: true,
              votes_enabled: true,
              awesome_votes_enabled_by_status: true,
              awesome_votes_enabled_states: %w(accepted)
            }
          }
        )
      end

      it "exposes status restriction meta" do
        expect(meta[:awesome_votes_enabled_by_status]).to be(true)
        expect(meta[:awesome_votes_enabled_states]).to eq(%w(accepted))
      end

      context "with only disallowed-status proposals" do
        before { create(:proposal, :evaluating, component: proposal_component) }

        it "sets can_vote false" do
          expect(meta[:can_vote]).to be(false)
        end
      end

      context "with an allowed unvoted proposal" do
        before { create(:proposal, :accepted, component: proposal_component) }

        it "sets can_vote true" do
          expect(meta[:can_vote]).to be(true)
        end
      end
    end
  end
end
