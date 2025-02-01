# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    RSpec.describe MagicToken, type: :model do
      let(:user) { create(:user) }

      describe "validations" do
        it "is valid with a user, magic_token, and expires_at" do
          magic_token = build(:magic_token, user: user)
          expect(magic_token).to be_valid
        end

        it "is invalid without a user" do
          magic_token = build(:magic_token, user: nil)
          expect(magic_token).not_to be_valid
          expect(magic_token.errors[:user]).to include("must exist")
        end

        it "is invalid with a duplicate magic_token" do
          create(:magic_token, magic_token: "unique_token", user: user)
          magic_token = build(:magic_token, magic_token: "unique_token", user: user)
          expect(magic_token).not_to be_valid
          expect(magic_token.errors[:magic_token]).to include("has already been taken")
        end
      end

      describe "callbacks" do
        it "sets a URL-safe encoded magic_token before validation" do
          magic_token = build(:magic_token, magic_token: nil, user: user)
          magic_token.save
          expect(magic_token.magic_token).not_to be_nil
          expect(magic_token.magic_token).to match(/^[A-Za-z0-9\-_=]+$/)
        end

        it "sets a magic_token before creation" do
          magic_token = build(:magic_token, magic_token: nil, user: user)
          magic_token.save
          expect(magic_token.magic_token).not_to be_nil
          expect(magic_token.magic_token.length).to be > 20
        end

        it "sets an expires_at before creation" do
          magic_token = build(:magic_token, expires_at: nil, user: user)
          magic_token.save
          expect(magic_token.expires_at).to be > Time.current
        end
      end

      describe "#valid_token?" do
        it "returns true if the token is not expired" do
          magic_token = create(:magic_token, expires_at: 1.hour.from_now, user: user)
          expect(magic_token.valid_token?).to be true
        end

        it "returns false if the token is expired" do
          magic_token = create(:magic_token, expires_at: 1.hour.ago, user: user)
          expect(magic_token.valid_token?).to be false
        end
      end

      describe "#mark_as_used" do
        it "destroys the magic token" do
          magic_token = create(:magic_token, user: user)
          expect { magic_token.mark_as_used }.to change(described_class, :count).by(-1)
        end
      end
    end
  end
end
