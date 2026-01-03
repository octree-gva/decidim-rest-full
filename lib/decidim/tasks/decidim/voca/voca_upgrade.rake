# frozen_string_literal: true

Rake::Task["decidim:choose_target_plugins"].enhance do
  ENV["FROM"] = "#{ENV.fetch("FROM", nil)},decidim_rest_full" unless ENV["FROM"].to_s.include?("decidim_rest_full")
end

Rake::Task["decidim:upgrade"].enhance do
  Rake::Task["decidim_rest_full:install:migrations"].invoke if Rake::Task.task_defined?("decidim_rest_full:install:migrations")
end
