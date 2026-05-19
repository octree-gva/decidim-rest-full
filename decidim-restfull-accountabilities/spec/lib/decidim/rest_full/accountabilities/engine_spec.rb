# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Accountabilities::Engine do
  it "registers accountability.read permission" do
    keys = Decidim::RestFull::Core::PermissionRegistry.all.map(&:key)
    expect(keys).to include("accountability.read")
  end
end
