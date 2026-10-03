# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::ImpersonateResourceOwnerFromCredentials do
  let(:organization) { create(:organization, available_locales: ["en"]) }
  let(:api_client) do
    api_client = create(:api_client, organization:, scopes: %w(oauth public))
    api_client.permissions = [
      api_client.permissions.build(permission: "oauth.impersonate"),
      api_client.permissions.build(permission: "oauth.impersonate.register"),
      api_client.permissions.build(permission: "oauth.extended_data.update")
    ]
    api_client.save!
    api_client.reload
  end

  describe "#validate_params!" do
    let(:command) { described_class.new(api_client, params, organization) }

    before do
      allow(command).to receive(:ability).and_return(double(authorize!: true))
    end

    context "when user does not exist and register_on_missing is false" do
      let(:params) do
        {
          username: "nonexistent_user",
          meta: {
            register_on_missing: false
          }
        }
      end

      it "raises NotFound exception" do
        expect do
          command.send(:validate_params!)
        end.to raise_error(Decidim::RestFull::Core::ApiException::NotFound, "User not found. To create one, user meta.register_on_missing")
      end
    end

    context "when user does not exist and register_on_missing is not set" do
      let(:params) do
        {
          username: "nonexistent_user"
        }
      end

      it "raises NotFound exception" do
        expect do
          command.send(:validate_params!)
        end.to raise_error(Decidim::RestFull::Core::ApiException::NotFound, "User not found. To create one, user meta.register_on_missing")
      end
    end

    context "when user does not exist and register_on_missing is true" do
      let(:params) do
        {
          username: "new_user",
          meta: {
            register_on_missing: true
          }
        }
      end

      it "does not raise an exception" do
        expect do
          command.send(:validate_params!)
        end.not_to raise_error
      end
    end

    context "when register_on_missing is the string false" do
      let(:params) do
        {
          username: "nonexistent_user",
          meta: {
            register_on_missing: "false"
          }
        }
      end

      it "raises NotFound exception" do
        expect do
          command.send(:validate_params!)
        end.to raise_error(Decidim::RestFull::Core::ApiException::NotFound)
      end
    end
  end

  describe "#call" do
    let(:command) { described_class.new(api_client, params, organization) }

    context "when user does not exist and register_on_missing is true" do
      let(:params) do
        {
          username: "new_user",
          meta: {
            register_on_missing: true,
            skip_confirmation_on_register: true
          }
        }
      end

      it "creates a new user" do
        expect do
          command.call
        end.to change(Decidim::User, :count).by(1)
      end

      it "broadcasts :ok" do
        expect(command.call).to broadcast(:ok)
      end

      it "creates user with correct attributes" do
        command.call
        user = Decidim::User.find_by(nickname: "new_user", organization:)
        expect(user).to be_present
        expect(user.email).to eq("new_user@example.org")
        expect(user.name).to eq("New User")
        expect(user.admin).to be(false)
      end

      it "sets accepted_tos_version in the past when accept_tos_on_register is false" do
        command.call
        user = Decidim::User.find_by(nickname: "new_user", organization:)
        expect(user.accepted_tos_version).to be < organization.tos_version
      end
    end

    context "when accept_tos_on_register is true" do
      let(:params) do
        {
          username: "tos_user",
          meta: {
            register_on_missing: true,
            accept_tos_on_register: true,
            skip_confirmation_on_register: true
          }
        }
      end

      it "sets accepted_tos_version at or after org tos_version" do
        command.call
        user = Decidim::User.find_by(nickname: "tos_user", organization:)
        expect(user.accepted_tos_version).to be >= organization.tos_version
      end
    end

    context "when register permission is missing" do
      let(:api_client) do
        api_client = create(:api_client, organization:, scopes: %w(oauth public))
        api_client.permissions = [
          api_client.permissions.build(permission: "oauth.impersonate")
        ]
        api_client.save!
        api_client.reload
      end

      let(:params) do
        {
          username: "new_user",
          meta: { register_on_missing: true, skip_confirmation_on_register: true }
        }
      end

      it "broadcasts :error" do
        expect(command.call).to broadcast(:error)
      end
    end

    context "when extra is present without extended_data.update" do
      let(:api_client) do
        api_client = create(:api_client, organization:, scopes: %w(oauth public))
        api_client.permissions = [
          api_client.permissions.build(permission: "oauth.impersonate"),
          api_client.permissions.build(permission: "oauth.impersonate.register")
        ]
        api_client.save!
        api_client.reload
      end

      let(:params) do
        {
          username: "extra_user",
          meta: { register_on_missing: true, skip_confirmation_on_register: true },
          extra: { phone_number: "+33123456789" }
        }
      end

      it "broadcasts :error" do
        expect(command.call).to broadcast(:error)
      end
    end

    context "when extra exceeds payload size" do
      let(:params) do
        {
          username: "big_extra",
          meta: { register_on_missing: true, skip_confirmation_on_register: true },
          extra: { blob: "x" * 100 }
        }
      end

      before do
        allow(Decidim::RestFull.config).to receive(:max_extended_data_payload_bytes).and_return(10)
      end

      it "broadcasts :error" do
        expect(command.call).to broadcast(:error)
      end
    end

    context "when updating existing user with empty extra" do
      let!(:user) { create(:user, :confirmed, organization:, nickname: "existing") }
      let(:params) { { username: "existing", extra: {} } }

      it "does not require extended_data.update and broadcasts ok" do
        expect(command.call).to broadcast(:ok)
        expect(user.reload.extended_data).to eq(user.extended_data)
      end
    end

    context "when updating existing user with extra" do
      let!(:user) { create(:user, :confirmed, organization:, nickname: "existing2", extended_data: {}) }
      let(:params) { { username: "existing2", extra: { locale_hint: "fr" } } }

      it "merges extended_data" do
        expect(command.call).to broadcast(:ok)
        expect(user.reload.extended_data["locale_hint"]).to eq("fr")
      end
    end
  end
end
