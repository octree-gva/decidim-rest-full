# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::MagicLinkRedirectUrlForm do
  let(:errors_scope) { "decidim.rest_full.forms.magic_link_redirect_url.errors" }

  let(:organization) do
    create(:organization, host: "tenant.example", external_domain_allowlist: ["partner.example"])
  end

  def form_with(url)
    described_class.new(redirect_url: url, organization:)
  end

  describe "validations" do
    it "is valid without redirect_url" do
      form = form_with(nil)
      expect(form).to be_valid
      expect(form.normalized_redirect_url).to be_nil
    end

    it "is valid with https URL on allowlisted host (www stripped)" do
      form = form_with("https://www.partner.example/path?q=1")
      expect(form).to be_valid
      expect(form.normalized_redirect_url).to eq("https://www.partner.example/path?q=1")
    end

    it "is valid when host matches organization host" do
      form = form_with("https://tenant.example/")
      expect(form).to be_valid
    end

    it "is valid for secondary_hosts" do
      organization.update!(secondary_hosts: ["alt.example"])
      form = form_with("https://alt.example/foo")
      expect(form).to be_valid
    end

    it "rejects http" do
      form = form_with("http://partner.example/")
      expect(form).not_to be_valid
      expect(form.errors[:redirect_url]).to include(I18n.t("#{errors_scope}.redirect_url.https_only"))
    end

    it "rejects non-ASCII" do
      form = form_with("https://partner.example/caf\u00e9")
      expect(form).not_to be_valid
      expect(form.errors[:redirect_url]).to include(I18n.t("#{errors_scope}.redirect_url.ascii_only"))
    end

    it "rejects host not in allowlist" do
      form = form_with("https://evil.example/")
      expect(form).not_to be_valid
      expect(form.errors[:redirect_url]).to include(I18n.t("#{errors_scope}.redirect_url.host_not_allowed"))
    end

    it "rejects userinfo in URL" do
      form = form_with("https://user:pass@partner.example/")
      expect(form).not_to be_valid
    end

    it "is invalid without organization" do
      form = described_class.new(redirect_url: "https://partner.example/", organization: nil)
      expect(form).not_to be_valid
      expect(form.errors[:organization]).to include(I18n.t("#{errors_scope}.organization_required"))
    end
  end
end
