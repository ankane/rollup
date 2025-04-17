require "bundler/setup"
require "logger" # for Active Record < 7.1
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

require_relative "support/active_record"

class Minitest::Test
  def setup
    User.delete_all
    Post.delete_all
    Rollup.delete_all
    $sql = []
  end

  # freeze time
  def now
    @now ||= Time.current
  end

  def create_users(interval: "day", browser: [], os: [], visits: [])
    step = interval_step(interval)
    3.times do |i|
      created_at = now.dup
      i.times do
        created_at -= step
      end
      User.create!(
        browser: browser[i],
        os: os[i],
        visits: visits[i],
        created_at: created_at
      )
    end
  end

  def interval_step(interval)
    case interval
    when "1s"
      1.second
    when "30s"
      30.seconds
    when "1m"
      1.minute
    when "5m"
      5.minutes
    when "quarter"
      3.months
    else
      1.send(interval)
    end
  end
end
