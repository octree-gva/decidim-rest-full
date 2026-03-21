# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::ImpersonateResourceOwnerFromCredentials do
  let(:organization) { create(:organization, available_locales: ["en"]) }
  let(:api_client) do
    api_client = create(:api_client, organization:, scopes: %w(oauth public))
    api_client.permissions = [
      api_client.permissions.build(permission: "oauth.impersonate")
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
  end

  describe "#call" do
    let(:command) { described_class.new(api_client, params, organization) }

    before do
      allow(command).to receive(:ability).and_return(double(authorize!: true))
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
      end
    end
  end
end
