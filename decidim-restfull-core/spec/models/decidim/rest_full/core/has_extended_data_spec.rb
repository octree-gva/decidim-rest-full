# frozen_string_literal: true

require "spec_helper"
require "decidim/rest_full/test/shared_examples/has_extended_data"

RSpec.describe Decidim::RestFull::Core::HasExtendedData do
  subject { organization }

  let(:organization) { create(:organization) }

  it_behaves_like "a model with HasExtendedData"

  it "does not include HasExtendedData on User" do
    expect(Decidim::User.ancestors).not_to include(Decidim::RestFull::Core::HasExtendedData)
  end
end
