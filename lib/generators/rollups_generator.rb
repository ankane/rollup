require "rails/generators/active_record"

# use rollups instead of rollup:install to avoid
# class Rollup < ActiveRecord::Base
# also works out nicely since it's the gem name
class RollupsGenerator < Rails::Generators::Base
  include ActiveRecord::Generators::Migration
  source_root File.join(__dir__, "templates")

  def copy_templates
    migration_template migration_source, "db/migrate/create_rollups.rb", migration_version: migration_version
  end

  def migration_source
    case ActiveRecord::Base.connection_config[:adapter].to_s
    when /postg/i
      "dimensions.rb"
    else
      "standard.rb"
    end
  end

  def migration_version
    "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
  end
end
