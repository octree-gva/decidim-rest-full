# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::UserApiEligibility do
  let(:organization) { create(:organization) }

  describe ".eligible?" do
    it "is true for confirmed non-blocked users" do
      user = create(:user, :confirmed, organization:)
      expect(described_class.eligible?(user)).to be(true)
    end

    it "is false when unconfirmed" do
      user = create(:user, :confirmed, organization:)
      user.update_columns(confirmed_at: nil) # rubocop:disable Rails/SkipsModelValidations
      expect(described_class.eligible?(user)).to be(false)
    end

    it "is false when blocked" do
      user = create(:user, :confirmed, :blocked, organization:)
      expect(described_class.eligible?(user)).to be(false)
    end
  end

  describe ".assert!" do
    it "raises for unconfirmed users" do
      user = create(:user, :confirmed, organization:)
      user.update_columns(confirmed_at: nil) # rubocop:disable Rails/SkipsModelValidations
      expect { described_class.assert!(user) }.to raise_error(
        Decidim::RestFull::Core::ApiException::BadRequest, "User unconfirmed"
      )
    end
  end
end
