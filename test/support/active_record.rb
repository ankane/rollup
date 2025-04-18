require "active_record"

$adapter = ENV["ADAPTER"] || "postgresql"
puts "Using #{$adapter}"

def postgresql?
  $adapter == "postgresql"
end

def mysql?
  $adapter == "mysql" || $adapter == "trilogy"
end

def trilogy?
  $adapter == "trilogy"
end

def sqlite?
  $adapter == "sqlite"
end

def dimensions_supported?
  postgresql?
end

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Migration.verbose = false unless ENV["VERBOSE"]

Time.zone = sqlite? ? "Etc/UTC" : "Eastern Time (US & Canada)"

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

if ActiveRecord::VERSION::STRING.to_f >= 7.2
  ActiveRecord::Base.attributes_for_inspect = :all
end

if ActiveRecord::VERSION::STRING.to_f == 8.0
  ActiveSupport.to_time_preserves_timezone = :zone
elsif ActiveRecord::VERSION::STRING.to_f == 7.2
  ActiveSupport.to_time_preserves_timezone = true
end

ActiveRecord::Base.logger = logger

if postgresql?
  ActiveRecord::Base.establish_connection adapter: "postgresql", database: "rollup_test"
elsif trilogy?
  ActiveRecord::Base.establish_connection adapter: "trilogy", database: "rollup_test", host: "127.0.0.1"
elsif mysql?
  ActiveRecord::Base.establish_connection adapter: "mysql2", database: "rollup_test"
else
  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
end

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.references :user
    t.datetime :posted_at
  end

  create_table :rollups, force: true do |t|
    t.string :name, null: false
    t.string :interval, null: false
    t.datetime :time, null: false
    t.jsonb :dimensions, null: false, default: {} if dimensions_supported?
    t.float :value
  end
  if dimensions_supported?
    add_index :rollups, [:name, :interval, :time, :dimensions], unique: true
  else
    add_index :rollups, [:name, :interval, :time], unique: true
  end

  create_table :users, force: true do |t|
    t.string :os
    t.string :browser
    t.jsonb :properties if dimensions_supported?
    t.integer :visits
    t.date :joined_on
    t.timestamps
  end
end

class Post < ActiveRecord::Base
  belongs_to :user

  self.rollup_column = :posted_at
end

class User < ActiveRecord::Base
  has_many :posts
end

$sql = []
ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
  $sql << payload[:sql]
end
