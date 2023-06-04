require_relative "test_helper"

require "rails/generators/test_case"
require "generators/rollups_generator"

class RollupsGeneratorTest < Rails::Generators::TestCase
  tests RollupsGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  def test_works
    run_generator
    assert_migration "db/migrate/create_rollups.rb", /create_table :rollups/
  end
end
