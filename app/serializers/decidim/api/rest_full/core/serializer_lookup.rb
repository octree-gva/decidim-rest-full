# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        # Resolves *ComponentSerializer classes from component +manifest_name+ (e.g. +proposals+,
        # +blogs+, +meetings+) to the correct +core+ / +proposals+ / +blogs+ namespace.
        module SerializerLookup
          module_function

          def component_serializer_class_for(manifest_name)
            name = manifest_name.to_s
            singular = name.singularize.camelize
            class_name = "#{singular}ComponentSerializer"
            case name
            when "proposals"
              "::Decidim::Api::RestFull::Proposals::#{class_name}".constantize
            when "blogs"
              "::Decidim::Api::RestFull::Blogs::#{class_name}".constantize
            else
              "::Decidim::Api::RestFull::Core::#{class_name}".constantize
            end
          end
        end
      end
    end
  end
end
