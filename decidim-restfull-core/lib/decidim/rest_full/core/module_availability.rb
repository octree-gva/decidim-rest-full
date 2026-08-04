# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Per-organization RestFull gates via decidim-toggle JSON.
      # Missing Toggle row → everything enabled (defaults true).
      #
      # Built-in feature maps ship below; external modules (and feature gems) also
      # register via +Extension#toggle_feature+ / +Extension#controller_paths+.
      class ModuleAvailability
        MODULE_NAME = "decidim_restfull"

        FEATURE_MODULES = [
          :proposals, :blogs, :debates, :surveys, :forms, :meetings, :attachments, :budgets, :accountabilities
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
          accountabilities: "decidim-restfull-accountabilities"
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
          accountability: :accountabilities
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
          "accountabilities" => :accountabilities
        }.freeze

        class << self
          def reset!
            @feature_order = FEATURE_MODULES.dup
            @feature_gems = FEATURE_GEMS.dup
            @scope_features = SCOPE_FEATURES.dup
            @controller_path_features = CONTROLLER_PATH_FEATURES.dup
          end

          def feature_modules
            @feature_order
          end

          def feature_gems
            @feature_gems
          end

          def scope_features
            @scope_features
          end

          def controller_path_features
            @controller_path_features
          end

          # +gem:+ RubyGems name for +Decidim::Toggle.gem_present?+ (+nil+ = always present).
          def register_feature!(feature, gem: nil)
            feature = feature.to_sym
            feature_gems[feature] = gem
            feature_modules << feature unless feature_modules.include?(feature)
            sync_config_form_attribute!(feature)
            feature
          end

          def register_controller_path!(segment, feature:)
            controller_path_features[segment.to_s] = feature.to_sym
          end

          def register_scope_feature!(scope, feature)
            scope_features[scope.to_sym] = feature.is_a?(Array) ? feature.map(&:to_sym) : feature.to_sym
          end

          def enabled?(organization)
            cast_bool(raw_config(organization)[:enabled], default: true)
          end

          def feature_gem_present?(feature)
            feature = feature.to_sym
            return false unless feature_gems.has_key?(feature)

            gem_name = feature_gems[feature]
            return true if gem_name.nil?

            Decidim::Toggle.gem_present?(gem_name)
          end

          def available_feature_modules
            feature_modules.select { |feature| feature_gem_present?(feature) }
          end

          def module_enabled?(organization, feature)
            return false unless enabled?(organization)
            return false unless feature_gem_present?(feature)

            key = :"#{feature}_enabled"
            cast_bool(raw_config(organization)[key], default: true)
          end

          def scope_enabled?(organization, scope)
            return false unless enabled?(organization)

            feature = scope_features[scope.to_sym]
            return true if feature.nil?

            Array(feature).any? { |f| module_enabled?(organization, f) }
          end

          def feature_for_controller(controller)
            controller.controller_path.split("/").reverse_each do |segment|
              feature = controller_path_features[segment]
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

          def sync_config_form_attribute!(feature)
            return unless defined?(Decidim::RestFull::Core::Admin::ConfigForm)

            attr = :"#{feature}_enabled"
            form = Decidim::RestFull::Core::Admin::ConfigForm
            return if form.attribute_types.key?(attr.to_s)

            form.attribute attr, :boolean, default: true
          end

          def cast_bool(value, default:)
            return default if value.nil?

            ActiveModel::Type::Boolean.new.cast(value)
          end
        end

        reset!
      end
    end
  end
end
