# frozen_string_literal: true

module Decidim
  module RestFull
    # Creates an ApiClient.
    class CreateApiClient < Decidim::Command
      # Initializes the command.
      #
      # form - The source fo data for this ApiClient.
      def initialize(form)
        @form = form
      end

      def call
        return broadcast(:invalid) unless @form.valid?

        api_client = Decidim.traceability.create!(
          ApiClient,
          @form.current_user,
          **api_client_attributes
        )

        broadcast(:ok, api_client)
      rescue ActiveRecord::RecordInvalid
        broadcast(:invalid)
      end

      def api_client_attributes
        {
          organization: @form.current_organization,
          name: @form.name,
          decidim_organization_id: @form.decidim_organization_id,
          scopes: @form.scopes.push("public").uniq
        }
      end
    end
  end
end
