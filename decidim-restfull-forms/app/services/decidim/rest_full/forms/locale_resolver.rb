# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      # Resolves effective locale for questionnaire projection and error messages.
      class LocaleResolver
        Result = Struct.new(:locale, :requested_locale, :fallback_from, keyword_init: true)

        def initialize(organization:, user: nil, params: {}, accept_language: nil)
          @organization = organization
          @user = user
          @params = params
          @accept_language = accept_language
        end

        def resolve!
          requested = explicit_locale || accept_language_locale
          raise Decidim::RestFull::Core::ApiException::BadRequest, "invalid_locale" if requested && available.exclude?(normalize(requested))

          effective = pick_effective(requested)
          fallback = requested && normalize(requested) != effective ? normalize(requested) : nil
          Result.new(
            locale: effective,
            requested_locale: requested ? normalize(requested) : effective,
            fallback_from: fallback
          )
        end

        def meta_hash
          r = resolve!
          {
            locale: r.locale,
            requested_locale: r.requested_locale,
            fallback_from: r.fallback_from
          }
        end

        private

        attr_reader :organization, :user, :params, :accept_language

        def available
          @available ||= organization.available_locales.map { |l| normalize(l) }
        end

        def explicit_locale
          loc = params[:locale] || params["locale"]
          loc.presence
        end

        def accept_language_locale
          return nil if accept_language.blank?

          accept_language.split(",").each do |part|
            tag = part.split(";").first.to_s.strip
            next if tag.blank?

            normalized = normalize(tag)
            return normalized if available.include?(normalized)

            base = normalized.split("-").first
            match = available.find { |a| a == base || a.start_with?("#{base}-") }
            return match if match
          end
          nil
        end

        def pick_effective(requested)
          return normalize(requested) if requested && available.include?(normalize(requested))

          if user&.locale.present?
            ul = normalize(user.locale)
            return ul if available.include?(ul)
          end

          normalize(organization.default_locale)
        end

        def normalize(locale)
          locale.to_s.tr("_", "-").downcase
        end
      end
    end
  end
end
