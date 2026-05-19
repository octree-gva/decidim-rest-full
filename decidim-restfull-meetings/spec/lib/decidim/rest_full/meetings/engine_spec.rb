# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Meetings::Engine do
  it "registers meetings.read permission" do
    keys = Decidim::RestFull::Core::PermissionRegistry.all.map(&:key)
    expect(keys).to include("meetings.read")
  end
end
