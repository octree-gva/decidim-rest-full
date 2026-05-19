# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Sortition::Engine do
  it "registers sortitions.read permission" do
    keys = Decidim::RestFull::Core::PermissionRegistry.all.map(&:key)
    expect(keys).to include("sortitions.read")
  end
end
