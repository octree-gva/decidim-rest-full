# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::WebhookDispatcher do
  include ActiveJob::TestHelper

  let(:organization) { create(:organization) }
  let(:component) { create(:proposal_component, organization:) }
  let(:dispatcher) { described_class.instance }

  before do
    allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:module_enabled?)
      .with(organization, :proposals).and_return(true)
  end

  def handle(name, proposal)
    allow(proposal).to receive(:organization).and_return(organization)
    dispatcher.handle_proposals(name, { resource: proposal })
  end

  it "maps proposal_published to proposal_creation.succeeded" do
    proposal = create(:proposal, :published, component:)
    expect { handle("decidim.events.proposals.proposal_published", proposal) }
      .to have_enqueued_job(Decidim::RestFull::Proposals::ProposalWebhookJob)
      .with("proposal_creation.succeeded", proposal.id, organization.id)
  end

  it "maps draft create to draft_proposal_creation.succeeded" do
    proposal = create(:proposal, component:, published_at: nil)
    expect { handle("decidim.proposals.create_proposal:after", proposal) }
      .to have_enqueued_job(Decidim::RestFull::Proposals::ProposalWebhookJob)
      .with("draft_proposal_creation.succeeded", proposal.id, organization.id)
  end

  it "maps draft update to draft_proposal_update.succeeded" do
    proposal = create(:proposal, component:, published_at: nil)
    expect { handle("decidim.proposals.update_proposal:after", proposal) }
      .to have_enqueued_job(Decidim::RestFull::Proposals::ProposalWebhookJob)
      .with("draft_proposal_update.succeeded", proposal.id, organization.id)
  end

  it "maps published update to proposal_update.succeeded" do
    proposal = create(:proposal, :published, component:)
    expect { handle("decidim.proposals.update_proposal:after", proposal) }
      .to have_enqueued_job(Decidim::RestFull::Proposals::ProposalWebhookJob)
      .with("proposal_update.succeeded", proposal.id, organization.id)
  end

  it "ignores unknown notification names" do
    proposal = create(:proposal, :published, component:)
    expect { handle("decidim.events.unknown", proposal) }
      .not_to have_enqueued_job(Decidim::RestFull::Proposals::ProposalWebhookJob)
  end

  it "no-ops when proposals module is disabled" do
    proposal = create(:proposal, :published, component:)
    allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:module_enabled?)
      .with(organization, :proposals).and_return(false)
    expect { handle("decidim.events.proposals.proposal_published", proposal) }
      .not_to have_enqueued_job(Decidim::RestFull::Proposals::ProposalWebhookJob)
  end
end
