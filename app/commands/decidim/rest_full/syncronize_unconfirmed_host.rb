# frozen_string_literal: true

module Decidim
  module RestFull
    class SyncronizeUnconfirmedHost < Decidim::Command
      attr_accessor :unconfirmed_host, :organization

      def initialize(organization)
        @organization = organization
        @unconfirmed_host = organization.extended_data.data["unconfirmed_host"]
      end

      ##
      # Do a reverse dns lookup over unconfirmed_host and check if it is linked to all of the loadbalancer_ips.
      def call
        return if unconfirmed_host.blank?
        raise Decidim::RestFull::ApiException::BadRequest, "The unconfirmed host cannot be the same as the current host." if organization.host == unconfirmed_host

        ips = Decidim::RestFull.config.loadbalancer_ips.map { |ip| IPAddr.new(ip) }
        return update_host! if ips.empty?

        # DNS lookup for unconfirmed_host
        dns_lookup = Resolv.getaddresses(unconfirmed_host)
        raise Decidim::RestFull::ApiException::NotFound, "Unconfirmed host #{unconfirmed_host} does not resolve." if dns_lookup.empty?
        # For each ip, check if the reverse dns lookup is the unconfirmed_host
        if ips.any? { |ip| dns_lookup.exclude?(ip.to_s) }
          raise Decidim::RestFull::ApiException::NotFound, "Unconfirmed host #{unconfirmed_host} does not resolve to all of the loadbalancer ips."
        end

        # If all is good, update the host
        update_host!
      end

      private

      def update_host!
        organization.update!(host: unconfirmed_host)
        organization.extended_data.data["unconfirmed_host"] = nil
        organization.extended_data.save!
      end
    end
  end
end
