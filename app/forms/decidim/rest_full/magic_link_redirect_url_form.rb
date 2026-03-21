# frozen_string_literal: true

module Decidim
  module RestFull
    # Validates optional `redirect_url` for magic link creation (HTTPS, printable ASCII, host allowlist).
    class MagicLinkRedirectUrlForm < Decidim::Form
      ERRORS_SCOPE = "decidim.rest_full.forms.magic_link_redirect_url.errors"
      # Everything after "https://" must be printable ASCII (space–~, i.e. 0x20–0x7E): no tabs, no Unicode/IDN in raw form.
      HTTPS_REMAINDER_PRINTABLE_ASCII = /\A[ -~]*\z/

      attribute :redirect_url, String
      attribute :organization, Object

      validate :validate_redirect_url_rules

      # After a successful validation, stripped value (or nil if omitted).
      def normalized_redirect_url
        redirect_url.presence
      end

      private

      def validate_redirect_url_rules
        return if validate_organization_required

        value = redirect_url.to_s.strip
        self.redirect_url = value.presence
        return if redirect_url.blank?

        # Before URI.parse: non-ASCII in path/query can raise URI::InvalidURIError; reject as ascii_only.
        return if validate_redirect_url_ascii_only

        uri = URI.parse(redirect_url)
        return if validate_redirect_url_https_only(uri)
        return if validate_redirect_url_host_blank(uri)
        return if validate_redirect_url_userinfo(uri)

        normalized_host = normalize_host(uri.host)

        validate_redirect_url_host_not_allowed(normalized_host)
      rescue URI::InvalidURIError
        validate_redirect_url_invalid
      end

      def validate_organization_required
        return false if organization

        errors.add(:organization, t_error(:organization_required))
        true
      end

      def validate_redirect_url_ascii_only
        return false unless redirect_url.match?(%r{\Ahttps://}i)

        remainder = redirect_url.sub(%r{\Ahttps://}i, "")
        return false if remainder.match?(HTTPS_REMAINDER_PRINTABLE_ASCII)

        errors.add(:redirect_url, t_error(:ascii_only, subscope: :redirect_url))
        true
      end

      def validate_redirect_url_https_only(uri)
        return false if uri.scheme == "https"

        errors.add(:redirect_url, t_error(:https_only, subscope: :redirect_url))
        true
      end

      def validate_redirect_url_host_blank(uri)
        return false if uri.host.present?

        errors.add(:redirect_url, t_error(:host_blank, subscope: :redirect_url))
        true
      end

      def validate_redirect_url_userinfo(uri)
        return false if uri.userinfo.blank?

        errors.add(:redirect_url, t_error(:userinfo, subscope: :redirect_url))
        true
      end

      def validate_redirect_url_host_not_allowed(host)
        errors.add(:redirect_url, t_error(:host_not_allowed, subscope: :redirect_url)) unless allowed_host?(host)
      end

      def validate_redirect_url_invalid
        errors.add(:redirect_url, t_error(:invalid_url, subscope: :redirect_url))
      end

      def t_error(key, subscope: nil)
        suffix = subscope ? "#{subscope}.#{key}" : key.to_s
        I18n.t("#{ERRORS_SCOPE}.#{suffix}")
      end

      def normalize_host(host)
        host.to_s.downcase.sub(/\Awww\./, "")
      end

      def allowed_host?(host)
        return true if host == normalize_host(organization.host)

        return true if organization.respond_to?(:secondary_hosts) && organization.secondary_hosts.present? && organization.secondary_hosts.any? { |h| normalize_host(h) == host }

        allowlist = organization.try(:external_domain_allowlist)
        return false if allowlist.blank?

        allowlist.any? { |entry| normalize_host(entry) == host }
      end
    end
  end
end
