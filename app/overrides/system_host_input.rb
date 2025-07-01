# frozen_string_literal: true

Deface::Override.new(
  virtual_path: "decidim/system/organizations/edit",
  name: "system_host_input",
  replace: "erb[loud]:contains('f.text_field :host')",
  text: <<-ERB
    <%#{" "}
      unconfirmed_host_help_text = if f.object.unconfirmed_host && f.object.unconfirmed_host != f.object.host
        t(
          "unconfirmed_host_pending_warning_html",
          scope: "decidim.rest_full.system.update_organization",
          unconfirmed_host: f.object.unconfirmed_host,
          host: f.object.host,#{"          "}
          a_records: Decidim::RestFull.config.loadbalancer_ips.select { |ip|#{" "}
            IPAddr.new(ip).ipv4?#{" "}
          }.map { |ip| "\#{f.object.unconfirmed_host} A \#{ip}" }.join("<br />").html_safe,
          aaa_records: Decidim::RestFull.config.loadbalancer_ips.select { |ip|#{" "}
            IPAddr.new(ip).ipv6?#{" "}
          }.map { |ip| "\#{f.object.unconfirmed_host} AAAA \#{ip}" }.join("<br />").html_safe
        )
      else#{" "}
        t(
          "unconfirmed_host_explaination_html",
          scope: "decidim.rest_full.system.update_organization",
          unconfirmed_host: f.object.unconfirmed_host,
          host: f.object.host,#{"          "}
          a_records: Decidim::RestFull.config.loadbalancer_ips.select { |ip|#{" "}
            IPAddr.new(ip).ipv4?#{" "}
          }.map { |ip| "\#{f.object.unconfirmed_host} A \#{ip}" }.join("<br />").html_safe,
          aaa_records: Decidim::RestFull.config.loadbalancer_ips.select { |ip|#{" "}
            IPAddr.new(ip).ipv6?#{" "}
          }.map { |ip| "\#{f.object.unconfirmed_host} AAAA \#{ip}" }.join("<br />").html_safe
        )
      end

    %>
    <%= f.text_field :unconfirmed_host, help_text: unconfirmed_host_help_text, label: t("unconfirmed_host_label", scope: "decidim.rest_full.system.update_organization") %>
    <%= f.hidden_field :host %>
  ERB
)
