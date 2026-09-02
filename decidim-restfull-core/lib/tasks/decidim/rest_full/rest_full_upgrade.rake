# frozen_string_literal: true

# Dummy `bin/rails` does not load the gem-root Rakefile. Awesome's
# migrate_awesome_map_menu_categories_to_menu_taxonomies runs during
# copy_migrations and needs db:create before :environment.

Rake::Task["decidim:choose_target_plugins"].enhance do
  name = Decidim::RestFull::Core::Engine.railtie_name
  ENV["FROM"] = "#{ENV.fetch("FROM", nil)},#{name}" unless ENV["FROM"].to_s.include?(name)
end

if Rake::Task.task_defined?("decidim:upgrade")
  Rake::Task["decidim:upgrade"].enhance do
    name = Decidim::RestFull::Core::Engine.railtie_name
    Rake::Task["#{name}:webpacker:install"].invoke if Rake::Task.task_defined?("#{name}:webpacker:install")
  end
end

module Decidim
  module RestFull
    # Skip awesome map upgrade when dummy DB/schema is missing (test_app copy_migrations).
    module AwesomeMapUpgradeGuard
      TASK = "decidim_decidim_awesome:upgrade:migrate_awesome_map_menu_categories_to_menu_taxonomies"

      def invoke(*)
        AwesomeMapUpgradeGuard.install! if name == TASK
        super
      end

      def self.install!
        return unless Rake::Task.task_defined?(TASK)

        task = Rake::Task[TASK]
        return if task.instance_variable_get(:@rest_full_map_guard)

        task.prerequisites.unshift("db:create") unless task.prerequisites.first == "db:create"
        wrap_actions(task)
        task.instance_variable_set(:@rest_full_map_guard, true)
      end

      def self.wrap_actions(task)
        originals = task.actions.dup
        return if originals.empty?

        task.actions.clear
        task.enhance { |t, args| run_originals(originals, t, args) }
      end

      def self.run_originals(originals, task, args)
        return unless components_table?

        originals.each { |action| action.call(task, args) }
      end

      def self.components_table?
        ActiveRecord::Base.connection.data_source_exists?("decidim_components")
      rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
        false
      end
    end
  end
end

Rake::Task.prepend(Decidim::RestFull::AwesomeMapUpgradeGuard) unless Rake::Task < Decidim::RestFull::AwesomeMapUpgradeGuard
