# frozen_string_literal: true

require "spec_helper"
require "decidim/rest_full/test"

RSpec.describe Decidim::RestFull::Test do
  it "resolves the dev gem root" do
    expect(described_class.repo_root).to eq(File.expand_path("../../../..", __dir__))
  end
end
