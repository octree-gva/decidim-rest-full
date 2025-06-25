Deface::Override.new(
  virtual_path: "decidim/system/organizations/edit",
  name: "system_host_input",
  replace: "erb[loud]:contains('f.text_field :host')",
  text: <<-ERB
    <%= f.text_field :unconfirmed_host %>
  ERB
)