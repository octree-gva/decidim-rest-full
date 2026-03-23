# frozen_string_literal: true

# Load order: shared → core → proposals → blogs (see definitions/*.rb barrels).
require_relative "definitions/shared"
require_relative "definitions/core"
require_relative "definitions/proposals"
require_relative "definitions/blogs"
require_relative "definitions/comments"
