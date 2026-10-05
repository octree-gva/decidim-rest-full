# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::DraftProposals::DraftProposalsController do
  path "/draft_proposals/{id}/sync" do
    put "Update draft proposal" do
      tags "Draft Proposals"
      produces "application/json"
      operationId "updateDraftProposal"
      description <<~README
        Update a draft proposal owned by this API client.

        Drafts updated here stay hidden on the Decidim front-end. Drafts created in the Decidim UI are not editable through this API.

        Send `title` and `body` as strings. Do not send a locale. The server stores each field as an object with **one** locale key. The response includes only that key.

        The locale is the impersonated user's `locale`. When `locale` is null, the server uses the organization `default_locale`.

        Only an impersonation token (ROPC) is accepted. A service token is rejected.

        Field errors cover only the fields present in the request. `data.meta.publishable` tells you if the draft can be published. An empty `data` object does not move locales and does not write.

        ## Update sequence

        A draft keeps a single locale. Changing the user's locale and sending a new value runs two steps: **move**, then **overlay**.

        ### 1. Edited while the user locale is `fr`

        ```json
        {
          "title": {
            "fr": "J'aimerais de nouveaux bancs publiques avec des prises USB-C"
          },
          "body": {
            "fr": "<p>Lorem Ipsum...</p>"
          }
        }
        ```

        ### 2. The user locale becomes `en`, and the client sends a new title

        ```json
        {
          "data": {
            "title": "I would like new benches with USB-C charging ports"
          }
        }
        ```

        **Move.** Strings stay the same. Keys change to the current locale. `fr` is removed.

        ```json
        {
          "title": {
            "en": "J'aimerais de nouveaux bancs publiques avec des prises USB-C"
          },
          "body": {
            "en": "<p>Lorem Ipsum...</p>"
          }
        }
        ```

        **Overlay.** Only fields in the request are replaced. `body` was not sent, so it stays on the moved string.

        ```json
        {
          "title": {
            "en": "I would like new benches with USB-C charging ports"
          },
          "body": {
            "en": "<p>Lorem Ipsum...</p>"
          }
        }
        ```

        The same two steps apply for `es`, and for a null user locale resolved to the organization `default_locale`.
      README

      parameter name: "id", in: :path, schema: { type: :integer, description: "Draft Id" }, required: true
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        title: "Update Draft Proposal Payload",
        properties: {
          data: {
            type: :object,
            title: "Update Draft Proposal Payload Data",
            properties: {
              title: { type: :string, description: "Title of the draft. Stored under the impersonated user's locale, or the organization default_locale when that locale is null." },
              body: { type: :string, description: "Content of the draft. Stored under the same locale as title." }
            },
            description: "Payload to update in the proposal"
          }
        }, required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::DraftProposals::DraftProposalsController,
        action: :update_sync,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.draft"]
      ) do
        let!(:organization) { create(:organization, available_locales: %w(en fr es), default_locale: "en") }
        let(:valid_title) { "This is a valid proposal title sample" }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let!(:proposal) do
          prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
          prop.update(rest_full_application: Decidim::RestFull::Proposals::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
          prop.body = nil
          prop.title = nil
          prop.save(validate: false)
          prop
        end
        let(:id) { proposal.id }
        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }
        let(:component_id) { proposal_component.id }

        response "200", "Draft updated" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:draft_proposal_item_response)

          context "when updating the title in fr" do
            let(:user) { create(:user, locale: "fr", organization:, confirmed_at: Time.zone.now) }
            let(:body) { { data: { title: valid_title } } }

            run_test!(example_name: :ok_update_title_fr) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["title"]).to eq({ "fr" => valid_title })
              expect(proposal.reload.title).to eq({ "fr" => valid_title })
            end
          end

          context "when updating the title in en" do
            let(:user) { create(:user, locale: "en", organization:, confirmed_at: Time.zone.now) }
            let(:body) { { data: { title: valid_title } } }

            run_test!(example_name: :ok_update_title_en) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["title"]).to eq({ "en" => valid_title })
              expect(proposal.reload.title).to eq({ "en" => valid_title })
            end
          end

          context "when updating the title in es" do
            let(:user) { create(:user, locale: "es", organization:, confirmed_at: Time.zone.now) }
            let(:body) { { data: { title: valid_title } } }

            run_test!(example_name: :ok_update_title_es) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["title"]).to eq({ "es" => valid_title })
              expect(proposal.reload.title).to eq({ "es" => valid_title })
            end
          end

          context "when the user locale is nil" do
            let(:user) { create(:user, locale: nil, organization:, confirmed_at: Time.zone.now) }
            let(:body) { { data: { title: valid_title } } }

            run_test!(example_name: :ok_update_title_default_locale) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["title"]).to eq({ "en" => valid_title })
              expect(proposal.reload.title).to eq({ "en" => valid_title })
            end
          end

          context "when updating the body in en" do
            let(:user) { create(:user, locale: "en", organization:, confirmed_at: Time.zone.now) }
            let(:text) { "I am quiet a valid proposal, with one sentence that is long enough to be valid I think." }
            let(:body) { { data: { body: text } } }

            run_test!(example_name: :ok_update_body_en) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["body"]).to eq({ "en" => text })
              expect(proposal.reload.body).to eq({ "en" => text })
            end
          end

          context "when update nothing" do
            let(:user) { create(:user, locale: "en", organization:, confirmed_at: Time.zone.now) }
            let(:body) { { data: {} } }

            run_test!(example_name: :ok_empty) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["title"]["en"]).to be_nil
              expect(data["meta"]["publishable"]).to be(false)
              expect(proposal.reload.title).to be_blank
            end
          end

          context "when the user locale changes from fr to en" do
            let(:french_title) { "J'aimerais de nouveaux bancs publiques avec des prises USB-C" }
            let(:english_title) { "I would like new benches with USB-C charging ports" }
            let(:french_body) { "<p>Lorem Ipsum...</p>" }
            let(:user) { create(:user, locale: "en", organization:, confirmed_at: Time.zone.now) }
            let(:body) { { data: { title: english_title } } }

            before do
              proposal.title = { "fr" => french_title }
              proposal.body = { "fr" => french_body }
              proposal.save(validate: false)
            end

            run_test!(example_name: :ok_locale_switch_fr_to_en) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["title"]).to eq({ "en" => english_title })
              expect(data["attributes"]["body"]).to eq({ "en" => french_body })
              expect(proposal.reload.title).to eq({ "en" => english_title })
              expect(proposal.reload.body).to eq({ "en" => french_body })
            end
          end
        end

        response "400", "Bad Request" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

          context "when title is blank" do
            let(:body) { { data: { title: "" } } }

            run_test!(example_name: :bad_request_title_blank) do |example|
              data = JSON.parse(example.body)
              expect(response).to have_http_status(:bad_request)
              expect(data["error_details"]).to include(
                a_hash_including("code" => "blank", "field" => "title")
              )
            end
          end

          context "when title is too short" do
            let(:body) { { data: { title: "Abcdefghijklm" } } } # 13 chars, starts with cap, low caps ratio

            run_test!(example_name: :bad_request_title_too_short) do |example|
              data = JSON.parse(example.body)
              expect(data["error_details"]).to include(
                a_hash_including("code" => "too_short", "field" => "title")
              )
            end
          end

          context "when title must start with caps" do
            let(:body) { { data: { title: "this is a long enough title" } } }

            run_test!(example_name: :bad_request_title_must_start_with_caps) do |example|
              data = JSON.parse(example.body)
              expect(data["error_details"]).to include(
                a_hash_including("code" => "must_start_with_caps", "field" => "title")
              )
            end
          end

          context "when title has too many caps" do
            let(:body) { { data: { title: "THIS IS ALL CAPS TITLE HERE" } } }

            run_test!(example_name: :bad_request_title_too_much_caps) do |example|
              data = JSON.parse(example.body)
              expect(data["error_details"]).to include(
                a_hash_including("code" => "too_much_caps", "field" => "title")
              )
            end
          end

          context "when title is too long" do
            let(:body) { { data: { title: "A#{"b" * 150}" } } } # 151 chars, etiquette-clean

            run_test!(example_name: :bad_request_title_too_long) do |example|
              data = JSON.parse(example.body)
              expect(data["error_details"]).to include(
                a_hash_including("code" => "too_long", "field" => "title")
              )
            end
          end

          context "when the token is a service token" do
            let!(:bearer_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: nil, application: api_client) }
            let(:body) { { data: { title: valid_title } } }

            run_test!(example_name: :bad_request_service_token) do |example|
              data = JSON.parse(example.body)
              expect(response).to have_http_status(:bad_request)
              expect(data["error_description"]).to include("User required")
            end
          end

          context "when title and body are both invalid" do
            let(:body) { { data: { title: "PROPOSAL", body: "proposal 2" } } }

            run_test!(example_name: :bad_request_title_and_body_multi) do |example|
              data = JSON.parse(example.body)
              details = data["error_details"]
              expect(details.size).to be >= 4
              expect(details).to include(
                a_hash_including("code" => "too_short", "field" => "title"),
                a_hash_including("code" => "too_much_caps", "field" => "title"),
                a_hash_including("code" => "too_short", "field" => "body"),
                a_hash_including("code" => "must_start_with_caps", "field" => "body")
              )
              expect(data["error_description"]).to be_present
            end
          end
        end
      end
    end
  end
end
