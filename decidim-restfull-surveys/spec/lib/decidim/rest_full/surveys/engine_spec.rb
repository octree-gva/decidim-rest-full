# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Surveys::Engine do
  it "registers surveys.read permission" do
    keys = Decidim::RestFull::Core::PermissionRegistry.all.map(&:key)
    expect(keys).to include("surveys.read")
  end
end
