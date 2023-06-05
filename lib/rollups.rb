# dependencies
require "active_support"
require "groupdate"

ActiveSupport.on_load(:active_record) do
  # must come first
  require_relative "rollup"

  require_relative "rollup/model"
  extend Rollup::Model
  Rollup.rollup_column = :time

  # modules
  require_relative "rollup/aggregator"
  require_relative "rollup/utils"
  require_relative "rollup/version"
end
