module Decidim
  module RestFull
      module UpdateOrganizationFormOverride 
        extend ActiveSupport::Concern

        included do
          attribute :unconfirmed_host, String

          validates :unconfirmed_host, presence: true
          alias_method :decidim_rest_full_map_model, :map_model
          
          def map_model(model)
            decidim_rest_full_map_model(model)
            self.unconfirmed_host = model.extended_data["unconfirmed_host"] || model.host
          end

          private 
          def save_organization
            if unconfirmed_host.present?
              organization.extended_data["unconfirmed_host"] = form.unconfirmed_host
            end
            organization.host = self.host
            super
          end
        end

  
      end
    
  end
end