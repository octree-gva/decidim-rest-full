# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Reads extended_data at a dot path. Missing keys return {} (e.g. after compacting cleared values).
      module ExtendedDataAtPath
        module_function

        def fetch(data, object_path)
          return data if object_path == "."

          object_path.split(".").reduce(data) do |current, key|
            return {} unless current.is_a?(Hash) && current.has_key?(key)

            current[key]
          end
        end
      end
    end
  end
end
