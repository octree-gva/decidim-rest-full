# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe User do
    let(:user) { create(:user) } # Assuming you have a factory for Decidim::User

    describe "rest_full_magic_token association" do
      it "has one rest_full_magic_token" do
        expect(user).to respond_to(:rest_full_magic_token)
      end

      it "destroys the rest_full_magic_token when the user is destroyed" do
        magic_token = create(:magic_token, user: user)
        user.destroy
        expect { magic_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "#rest_full_generate_magic_token" do
      it "creates a new rest_full_magic_token for the user" do
        expect { user.rest_full_generate_magic_token }.to change(Decidim::RestFull::MagicToken, :count).by(1)
        expect(user.rest_full_magic_token).to be_present
      end

      it "destroys any existing rest_full_magic_token before creating a new one" do
        existing_token = create(:magic_token, user: user)
        user.rest_full_generate_magic_token
        expect(Decidim::RestFull::MagicToken.exists?(existing_token.id)).to be false
      end

      it "returns the newly created rest_full_magic_token" do
        magic_token = user.rest_full_generate_magic_token
        expect(magic_token).to be_a(Decidim::RestFull::MagicToken)
        expect(magic_token.user).to eq(user)
      end

      it "raises an error if the rest_full_magic_token cannot be created" do
        # Simulate a validation error by making the user invalid
        allow(user).to receive(:create_rest_full_magic_token!).and_raise(ActiveRecord::RecordInvalid)
        expect { user.rest_full_generate_magic_token }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
