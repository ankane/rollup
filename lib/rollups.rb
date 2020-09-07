# dependencies
require "active_support"
require "groupdate"

ActiveSupport.on_load(:active_record) do
  # must come first
  require "rollup"

  require "rollup/model"
  extend Rollup::Model

  # modules
  require "rollup/aggregator"
  require "rollup/utils"
  require "rollup/version"
end
