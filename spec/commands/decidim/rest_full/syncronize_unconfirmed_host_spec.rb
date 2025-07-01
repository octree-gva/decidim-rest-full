# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::SyncronizeUnconfirmedHost do
  let(:unconfirmed_host) { "unconfirmed.host.org" }
  let(:organization) do
    org = create(:organization, host: "my.host.org")
    org.extended_data.data["unconfirmed_host"] = unconfirmed_host
    org.extended_data.save!
    org
  end
  let(:ipv4_loadbalancer_ip) { Faker::Internet.ip_v4_address }
  let(:ipv6_loadbalancer_ip) { Faker::Internet.ip_v6_address }

  before do
    allow(Decidim::RestFull.config).to receive(:loadbalancer_ips).and_return([ipv4_loadbalancer_ip, ipv6_loadbalancer_ip])
  end

  describe "#call" do
    context "when Decidim::RestFull.config.loadbalancer_ips is empty" do
      before do
        allow(Decidim::RestFull.config).to receive(:loadbalancer_ips).and_return([])
      end

      it "update immediately the host" do
        expect { described_class.call(organization) }.to change(organization, :host).to(unconfirmed_host)
        expect(organization.extended_data.data["unconfirmed_host"]).to be_nil
      end
    end

    context "when the unconfirmed host is the same as the current host" do
      let(:organization) do
        org = create(:organization, host: unconfirmed_host)
        org.extended_data.data["unconfirmed_host"] = unconfirmed_host
        org.extended_data.save!
        org
      end

      it "raise an bad request error" do
        expect { described_class.call(organization) }.to raise_error(Decidim::RestFull::ApiException::BadRequest)
      end
    end

    context "when Decidim::RestFull.config.loadbalancer_ips is set with a ipv4" do
      before do
        allow(Decidim::RestFull.config).to receive(:loadbalancer_ips).and_return([ipv4_loadbalancer_ip])
      end

      context "when the IPv4 resolves to the unconfirmed host" do
        before do
          allow(Resolv).to receive(:getaddresses).with(unconfirmed_host).and_return([ipv4_loadbalancer_ip])
        end

        it "updates the host" do
          expect { described_class.call(organization) }.to change(organization, :host).to(unconfirmed_host)
        end
      end

      context "when the IPv4 does not resolve to the unconfirmed host" do
        before do
          allow(Resolv).to receive(:getaddresses).with(unconfirmed_host).and_return([Faker::Internet.ip_v4_address])
        end

        it "raise an not found error" do
          expect { described_class.call(organization) }.to raise_error(Decidim::RestFull::ApiException::NotFound)
        end
      end
    end

    context "when Decidim::RestFull.config.loadbalancer_ips is set with a ipv6" do
      before do
        allow(Decidim::RestFull.config).to receive(:loadbalancer_ips).and_return([ipv6_loadbalancer_ip])
      end

      context "when the IPv6 resolves to the unconfirmed host" do
        before do
          allow(Resolv).to receive(:getaddresses).with(unconfirmed_host).and_return([ipv6_loadbalancer_ip])
        end

        it "updates the host" do
          expect { described_class.call(organization) }.to change(organization, :host).to(unconfirmed_host)
        end
      end

      context "when the IPv6 does not resolve to the unconfirmed host" do
        before do
          allow(Resolv).to receive(:getaddresses).with(unconfirmed_host).and_return([Faker::Internet.ip_v6_address])
        end

        it "raise an not found error" do
          expect { described_class.call(organization) }.to raise_error(Decidim::RestFull::ApiException::NotFound)
        end
      end
    end

    context "when the unconfirmed host is not linked to all of the loadbalancer ips" do
      before do
        allow(Resolv).to receive(:getaddresses).with(unconfirmed_host).and_return([Faker::Internet.ip_v4_address, Faker::Internet.ip_v6_address])
      end

      it "raise an not found error" do
        expect { described_class.call(organization) }.to raise_error(Decidim::RestFull::ApiException::NotFound)
      end
    end

    context "when Decidim::RestFull.config.loadbalancer_ips is set with an invalid ip" do
      before do
        allow(Decidim::RestFull.config).to receive(:loadbalancer_ips).and_return([Faker::Name.name])
      end

      it "raise IPAddr::InvalidAddressError" do
        expect { described_class.call(organization) }.to raise_error(IPAddr::InvalidAddressError)
      end
    end
  end
end
