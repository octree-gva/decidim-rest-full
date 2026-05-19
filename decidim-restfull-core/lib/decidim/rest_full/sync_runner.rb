# frozen_string_literal: true

module Decidim
  module RestFull
    # Wraps synchronous API command work in a single DB transaction.
    module SyncRunner
      module_function

      def call(&)
        ActiveRecord::Base.transaction(&)
      end
    end
  end
end
