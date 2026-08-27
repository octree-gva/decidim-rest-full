# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Budgets::Engine do
  it "registers budgets.read permission" do
    keys = Decidim::RestFull::Core::PermissionRegistry.all.map(&:key)
    expect(keys).to include("budgets.read")
  end
end
