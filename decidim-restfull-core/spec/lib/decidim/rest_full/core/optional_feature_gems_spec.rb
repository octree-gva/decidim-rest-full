# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- cross-cutting optional-gem integration
RSpec.describe "optional decidim-restfull feature gems" do
  describe Decidim::RestFull::Core::DoorkeeperConfig do
    it "advertises only core scopes without registered feature scopes" do
      allow(Decidim::RestFull::Extension).to receive(:doorkeeper_optional_scopes).and_return([])

      expect(described_class.advertised_scopes).not_to include(:blogs, :proposals)
      expect(described_class::CORE_OPTIONAL_SCOPES).not_to include(:meetings, :debates)
    end

    it "filters advertised_scopes_for when feature gem scopes are absent" do
      organization = create(:organization)
      allow(Decidim::RestFull::Extension).to receive(:doorkeeper_optional_scopes).and_return([])
      allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:raw_config)
        .with(organization).and_return({ enabled: true }.with_indifferent_access)

      expect(described_class.advertised_scopes_for(organization)).not_to include(:proposals, :blogs)
      expect(described_class.advertised_scopes_for(organization)).to include(:public, :oauth)
    end
  end

  describe Decidim::RestFull::Core::Configuration do
    it "defaults to core permissions only; feature gems merge via Extension.register" do
      expect(described_class.default_available_permissions).not_to include("blogs", "proposals", "meetings")
    end

    it "receives events_for_proposals from the proposals gem when loaded" do
      skip "decidim-restfull-proposals not in bundle" unless Gem.loaded_specs.has_key?("decidim-restfull-proposals")

      expect(described_class.events_for_proposals).to include("proposal_creation.succeeded")
    end

    it "receives events_for_meetings from the meetings gem when loaded" do
      skip "decidim-restfull-meetings not in bundle" unless Gem.loaded_specs.has_key?("decidim-restfull-meetings")

      expect(described_class.events_for_meetings).to eq(%w(meetings.upcoming_reminder.succeeded))
    end
  end

  describe Decidim::RestFull::Core::PermissionRegistry do
    it "exposes no proposals permission group when nothing was registered for that scope" do
      # Missing feature gem ⇒ Extension.register never ran ⇒ empty scope.
      expect(described_class.by_scope(:proposals_missing_gem_probe)).to eq([])
    end

    it "does not register unimplemented system.users / system.server abilities" do
      keys = described_class.by_scope(:system).map(&:key)

      expect(keys).to include("oauth.read")
      expect(keys).not_to include(
        "system.users.update",
        "system.users.destroy",
        "system.server.restart",
        "system.server.exec"
      )
      expect(described_class.by_scope_and_group(:system, :rails)).to eq([])
    end

    it "lists extension-only scopes for the System API client permissions UI" do
      described_class.register(:whatsapp, "whatsapp.read", group: :whatsapp)

      expect(described_class.extension_ui_scopes).to include("whatsapp")
      expect(described_class.extension_ui_scopes).not_to include("proposals", "blogs")
    ensure
      described_class.send(:registry).delete("whatsapp.read")
    end
  end

  describe Decidim::RestFull::Core::WebhookEventCatalog do
    it "sync_from_configuration registers only core oauth/system events" do
      snapshot = described_class.entries.dup
      described_class.clear!
      described_class.sync_from_configuration!

      expect(described_class.all.map(&:scope).uniq).to match_array(%w(oauth system))
      expect(described_class.all.map(&:schema_key)).to all(start_with("wh_"))
    ensure
      described_class.instance_variable_set(:@entries, snapshot)
    end
  end

  describe Decidim::RestFull::Core::WebhookDispatcher do
    it "no-ops proposal events when the proposals webhook job is not available" do
      dispatcher = described_class.instance
      allow(dispatcher).to receive(:proposals_webhook_job_defined?).and_return(false)

      expect(Decidim::RestFull::Proposals::ProposalWebhookJob).not_to receive(:perform_later) if defined?(Decidim::RestFull::Proposals::ProposalWebhookJob)

      expect do
        dispatcher.handle_proposals("decidim.proposals.create_proposal:after", resource: nil)
      end.not_to raise_error
    end
  end

  describe Decidim::RestFull::Core::Admin::ConfigForm do
    let(:organization) { create(:organization) }
    let(:form) { described_class.from_model(organization).with_context(current_organization: organization) }

    it "disables proposals_enabled when the proposals gem is absent" do
      form.enabled = true
      allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:feature_gem_present?)
        .and_return(true)
      allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:feature_gem_present?)
        .with(:proposals).and_return(false)

      expect(form.attribute_disabled?(:proposals_enabled)).to be(true)
      expect(form.attribute_disabled?(:attachments_enabled)).to be(false)
    end

    it "omits disabled missing-gem attributes from to_h" do
      form.enabled = true
      form.proposals_enabled = true
      allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:feature_gem_present?)
        .and_return(true)
      allow(Decidim::RestFull::Core::ModuleAvailability).to receive(:feature_gem_present?)
        .with(:proposals).and_return(false)

      expect(form.to_h).not_to have_key(:proposals_enabled)
    end
  end

  describe Decidim::RestFull::Core::Ransackers do
    it "registers core ransackers without decidim-proposals loaded" do
      expect { described_class.register_ransackers! }.not_to raise_error
    end
  end

  describe Decidim::Api::RestFull::Core::SerializerLookup do
    it "falls back to a typed ComponentSerializer subclass when the adapter gem is absent" do
      allow(described_class).to receive(:safe_constant_defined?).and_return(false)
      klass = described_class.component_serializer_class_for("proposals")
      expect(klass).to be < Decidim::Api::RestFull::Core::ComponentSerializer
      expect(klass.record_type).to eq(:proposal_component)
    end

    it "resolves meetings serializer when decidim-restfull-meetings is loaded" do
      skip "decidim-restfull-meetings not in bundle" unless defined?(Decidim::Api::RestFull::Meetings::MeetingComponentSerializer)

      expect(described_class.component_serializer_class_for("meetings")).to eq(
        Decidim::Api::RestFull::Meetings::MeetingComponentSerializer
      )
    end

    it "resolves page serializer from core without a feature gem" do
      expect(described_class.component_serializer_class_for("pages")).to eq(
        Decidim::Api::RestFull::Core::PageComponentSerializer
      )
    end
  end

  describe Decidim::RestFull::Core::Ability do
    let(:organization) { create(:organization) }
    let(:api_client) do
      create(:api_client, organization:, scopes: %w(meetings)).tap do |client|
        client.permissions.create!(permission: "meetings.read")
      end
    end

    it "does not reference proposals when only meetings scope is used" do
      ability = described_class.new(api_client)
      skip "decidim-meetings not in bundle" unless defined?(Decidim::Meetings::Meeting)

      expect(ability.can?(:read, Decidim::Meetings::Meeting)).to be(true)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
