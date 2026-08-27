# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Debates::Engine do
  it "registers debates.read permission" do
    keys = Decidim::RestFull::Core::PermissionRegistry.all.map(&:key)
    expect(keys).to include("debates.read")
  end
end
