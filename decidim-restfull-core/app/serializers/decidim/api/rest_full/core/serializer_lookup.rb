# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        # Resolves *ComponentSerializer classes from component +manifest_name+ (e.g. +proposals+,
        # +blogs+, +meetings+) to +Decidim::Api::RestFull::*+ gem namespaces (+core+ is the fallback).
        module SerializerLookup
          module_function

          MANIFEST_SERIALIZER_MODULES = {
            "proposals" => "Decidim::Api::RestFull::Proposals",
            "blogs" => "Decidim::Api::RestFull::Blogs",
            "meetings" => "Decidim::Api::RestFull::Meetings",
            "debates" => "Decidim::Api::RestFull::Debates",
            "surveys" => "Decidim::Api::RestFull::Surveys",
            "budgets" => "Decidim::Api::RestFull::Budgets",
            "accountability" => "Decidim::Api::RestFull::Accountabilities"
          }.freeze

          def component_serializer_class_for(manifest_name)
            name = manifest_name.to_s
            class_name = "#{name.singularize.camelize}ComponentSerializer"
            base = MANIFEST_SERIALIZER_MODULES[name]
            if base
              qualified = "#{base}::#{class_name}"
              return qualified.constantize if safe_constant_defined?(qualified)
            end

            core_qualified = "Decidim::Api::RestFull::Core::#{class_name}"
            return core_qualified.constantize if safe_constant_defined?(core_qualified)

            # Relationship +type+ uses serializer.record_type (class-level). A bare
            # ComponentSerializer emits +"component"+ which fails OpenAPI other_component.
            typed_fallback_serializer_for(name)
          end

          def typed_fallback_serializer_for(manifest_name)
            type = "#{manifest_name.to_s.singularize}_component"
            @typed_fallback_serializers ||= {}
            @typed_fallback_serializers[type] ||= Class.new(Decidim::Api::RestFull::Core::ComponentSerializer) do
              set_type type.to_sym
            end
          end

          def safe_constant_defined?(name)
            Object.const_defined?(name, false)
          end
          private_class_method :safe_constant_defined?, :typed_fallback_serializer_for
        end
      end
    end
  end
end
