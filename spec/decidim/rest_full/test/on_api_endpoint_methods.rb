# frozen_string_literal: true

module Decidim
  module RestFull
    module Test
      module OnApiEndpointMethods
        def on_security(flow_type)
          yield if Decidim::RestFull::Test::GlobalContext.security_type == flow_type
        end

        def describe_api_endpoint(options = {}, &block)
          rest_full_validate_options!(options)
          scopes = options[:scopes].map(&:to_s)
          security_types = options[:security_types]
          is_protected = options.fetch(:is_protected, true)

          # Prepare host for the request
          rest_full_setup_api_context!(options)

          security_types.each do |security_type|
            Decidim::RestFull::Test::GlobalContext.security_type = security_type
            rest_full_validate_security_type!(security_type)

            context "when #{security_type}" do
              # Prepare security for the request (api_client and bearer_token)
              rest_full_setup_credential_flow!(scopes, is_protected) if security_type == :credentialFlow
              rest_full_setup_resource_owner_flow!(scopes, is_protected) if security_type == :impersonationFlow

              let(:security_type) { security_type }
              let(:Authorization) { "Bearer #{bearer_token.token}" }

              rest_full_handle_forbidden(security_type, options) if is_protected
              rest_full_handle_500_error(options)
              instance_eval(&block)
            end
          end
        end

        private

        def rest_full_validate_options!(options)
          [:controller, :action, :scopes, :security_types].each do |key|
            raise ArgumentError, "Missing option `#{key}`" unless options[key]
          end
          scopes = options[:scopes]
          raise ArgumentError, "scopes option must be an array" unless scopes.is_a?(Array)

          permissions = options[:permissions]
          raise ArgumentError, "permissions option must be an array" unless permissions.is_a?(Array)

          security_types = options[:security_types]
          raise ArgumentError, "security_types option must be an array" unless security_types.is_a?(Array)
        end

        def rest_full_setup_api_context!(options)
          scopes = options[:scopes].map(&:to_s)
          permissions = options[:permissions].map(&:to_s)

          let!(:organization) { create(:organization) }
          before do
            host! organization.host
          end

          let(:api_client) do
            api_client = create(:api_client, organization: organization, scopes: scopes)
            api_client.permissions = permissions.map do |permission|
              api_client.permissions.build(permission: permission)
            end
            api_client.save!
            api_client
          end
        end

        def rest_full_validate_security_type!(security_type)
          security_type_options = [:credentialFlow, :impersonationFlow]
          unless security_type_options.include?(security_type)
            suggestions = DidYouMean::SpellChecker.new(dictionary: security_type_options).correct(security_type)
            message = "Invalid security type `#{security_type}`. Must be one of: #{security_type_options.join(", ")}"
            message += ". Did you mean: #{suggestions.map { |s| "`#{s}`" }.join(", ")} ?" if suggestions.any?
            raise ArgumentError, message
          end
        end

        def rest_full_bearer_credential_flow!(scopes)
          let!(:bearer_token) { create(:oauth_access_token, scopes: scopes.join(" "), resource_owner_id: nil, application: api_client) }
        end

        def rest_full_bearer_resource_owner_flow!(scopes)
          let(:user) { create(:user, locale: "fr", organization: organization, confirmed_at: Time.zone.now) }
          let!(:bearer_token) { create(:oauth_access_token, scopes: scopes.join(" "), resource_owner_id: user.id, application: api_client) }
        end

        def rest_full_setup_credential_flow!(scopes, is_protected)
          rest_full_bearer_credential_flow!(scopes)
          security is_protected ? [{ credentialFlowBearer: scopes }] : []
        end

        def rest_full_setup_resource_owner_flow!(scopes, is_protected)
          rest_full_bearer_resource_owner_flow!(scopes)
          security is_protected ? [{ resourceOwnerFlowBearer: scopes }] : []
        end

        def rest_full_handle_forbidden_scopes(security_type, options)
          scopes = options[:scopes].map(&:to_s)
          available_scopes = %w(public oauth blogs proposals users)
          response "403", "Forbidden" do
            produces "application/json"
            schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
            scopes.each do |scope|
              wrong_scope = available_scopes.find { |s| scopes.exclude?(s) && s != scope }
              context "with invalid `#{wrong_scope}` scope" do
                rest_full_bearer_resource_owner_flow!([wrong_scope]) if security_type == :impersonationFlow
                rest_full_bearer_credential_flow!([wrong_scope]) if security_type == :credentialFlow
                run_test!(example_name: :"forbidden_#{security_type}") do |_example|
                  expect(response).to have_http_status(:forbidden)
                  expect(response.body).to include("Forbidden")
                end
              end
            end
          end
        end

        def rest_full_handle_forbidden_permissions(security_type, options)
          scopes = options[:scopes].map(&:to_s)
          permissions = options[:permissions].map(&:to_s)

          response "403", "Forbidden" do
            produces "application/json"
            schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
            permissions.each do |permission|
              context "without #{permission} permission" do
                let(:api_client) { create(:api_client, organization: organization, scopes: scopes) }

                rest_full_bearer_resource_owner_flow!(scopes) if security_type == :impersonationFlow
                rest_full_bearer_credential_flow!(scopes) if security_type == :credentialFlow
                run_test! do |_example|
                  expect(response).to have_http_status(:forbidden)
                  expect(response.body).to include("Forbidden")
                end
              end
            end
          end
        end

        def rest_full_handle_forbidden(security_type, options)
          rest_full_handle_forbidden_scopes(security_type, options)
          rest_full_handle_forbidden_permissions(security_type, options)
        end

        def rest_full_handle_500_error(options)
          action = options[:action]
          controller = options[:controller]

          response "500", "Internal Server Error" do
            consumes "application/json"
            produces "application/json"

            before do
              controller_instance = controller.new
              allow(controller_instance).to receive(action).and_raise(StandardError.new("Intentional error for testing"))
              allow(controller).to receive(:new).and_return(controller_instance)
            end

            schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

            run_test! do |response|
              expect(response.status).to eq(500)
              expect(response.body).to include("Internal Server Error")
            end
          end
        end
      end
    end
  end
end
