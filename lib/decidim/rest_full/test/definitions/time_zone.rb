# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:time_zone) do
  {
    type: :string,
    title: "Time Zone",
    description: "Time Zone identifier",
    enum: (["UTC"] + ActiveSupport::TimeZone.all.map { |t| t.tzinfo.name }).sort
  }.freeze
end
