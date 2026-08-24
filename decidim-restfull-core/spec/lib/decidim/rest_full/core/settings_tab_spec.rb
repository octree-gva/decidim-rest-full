# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::SettingsTab do
  it "registers a form_layout_partial that accepts Toggle locals" do
    path = Decidim::RestFull::Core::Engine.root.join(
      "app/views/decidim/rest_full/core/admin/_organization_settings_tab.html.erb"
    )

    expect(File.read(path).lines.first).to match(
      /<%#\s*locals:\s*\(organization:,\s*tab:\)\s*%>/
    )
  end
end
