# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Per-organization RestFull gates via decidim-toggle JSON.
      # Missing Toggle row → everything enabled (defaults true).
      class ModuleAvailability
        MODULE_NAME = "decidim_restfull"

        FEATURE_MODULES = [
          :proposals, :blogs, :debates, :surveys, :forms, :meetings, :attachments, :budgets, :accountabilities, :sortition
        ].freeze

        # Feature Toggle key → RubyGems name. +nil+ means shipped in core (always present).
        FEATURE_GEMS = {
          proposals: "decidim-restfull-proposals",
          blogs: "decidim-restfull-blogs",
          debates: "decidim-restfull-debates",
          surveys: "decidim-restfull-surveys",
          forms: "decidim-restfull-forms",
          meetings: "decidim-restfull-meetings",
          attachments: nil,
          budgets: "decidim-restfull-budgets",
          accountabilities: "decidim-restfull-accountabilities",
          sortition: "decidim-restfull-sortition"
        }.freeze

        # OAuth scope → feature key(s). Array means any-of.
        SCOPE_FEATURES = {
          blogs: :blogs,
          proposals: :proposals,
          debates: :debates,
          surveys: [:surveys, :forms],
          meetings: :meetings,
          attachments: :attachments,
          budgets: :budgets,
          accountability: :accountabilities,
          sortitions: :sortition
        }.freeze

        CONTROLLER_PATH_FEATURES = {
          "blogs" => :blogs,
          "blog_components" => :blogs,
          "proposals" => :proposals,
          "proposal_components" => :proposals,
          "draft_proposals" => :proposals,
          "vote_proposals" => :proposals,
          "debates" => :debates,
          "surveys" => :surveys,
          "forms" => :forms,
          "questionnaires" => :forms,
          "questions" => :forms,
          "answers" => :forms,
          "answer_options" => :forms,
          "questionnaire_responses" => :forms,
          "submission_requests" => :forms,
          "meetings" => :meetings,
          "attachments" => :attachments,
          "budgets" => :budgets,
          "accountability" => :accountabilities,
          "accountabilities" => :accountabilities,
          "sortitions" => :sortition,
          "sortition" => :sortition
        }.freeze

        class << self
          def enabled?(organization)
            cast_bool(raw_config(organization)[:enabled], default: true)
          end

          def feature_gem_present?(feature)
            feature = feature.to_sym
            return false unless FEATURE_GEMS.has_key?(feature)

            gem_name = FEATURE_GEMS[feature]
            return true if gem_name.nil?

            Decidim::Toggle.gem_present?(gem_name)
          end

          def available_feature_modules
            FEATURE_MODULES.select { |feature| feature_gem_present?(feature) }
          end

          def module_enabled?(organization, feature)
            return false unless enabled?(organization)
            return false unless feature_gem_present?(feature)

            key = :"#{feature}_enabled"
            cast_bool(raw_config(organization)[key], default: true)
          end

          def scope_enabled?(organization, scope)
            return false unless enabled?(organization)

            feature = SCOPE_FEATURES[scope.to_sym]
            return true if feature.nil?

            Array(feature).any? { |f| module_enabled?(organization, f) }
          end

          def feature_for_controller(controller)
            controller.controller_path.split("/").reverse_each do |segment|
              feature = CONTROLLER_PATH_FEATURES[segment]
              return feature if feature
            end
            nil
          end

          def ensure_available!(organization, feature: nil)
            raise Decidim::RestFull::Core::ApiException::NotImplemented, "Rest API is disabled" unless enabled?(organization)
            return if feature.blank?
            return if module_enabled?(organization, feature)

            raise Decidim::RestFull::Core::ApiException::NotImplemented, "#{feature} API is disabled"
          end

          def raw_config(organization)
            return {}.with_indifferent_access if organization.blank?
            return {}.with_indifferent_access unless defined?(Decidim::Toggle::OrganizationModuleConfig)

            Decidim::Toggle::OrganizationModuleConfig.find_by(
              decidim_organization_id: organization.id,
              module_name: MODULE_NAME
            )&.config&.with_indifferent_access || {}.with_indifferent_access
          end

          private

          def cast_bool(value, default:)
            return default if value.nil?

            ActiveModel::Type::Boolean.new.cast(value)
          end
        end
      end
    end
  end
end
