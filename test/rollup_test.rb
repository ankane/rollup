require_relative "test_helper"

class RollupTest < Minitest::Test
  def test_attributes
    User.create!
    User.rollup("Test")

    assert_equal 1, Rollup.count

    rollup = Rollup.last
    assert_equal "Test", rollup.name
    assert_equal "day", rollup.interval
    assert_equal now.to_date, rollup.time
    assert_empty rollup.dimensions if dimensions_supported?
    assert_equal 1, rollup.value
  end

  def test_rename
    create_users
    User.rollup("Test")
    Rollup.rename("Test", "New")
    assert_equal 3, Rollup.where(name: "New").count
    assert_equal 0, Rollup.where(name: "Test").count
  end

  def test_time_cast
    create_users
    User.rollup("Test")
    assert_equal now.to_date, Rollup.last.time
  end

  def test_inspect
    create_users
    User.rollup("Test")
    assert_match "time: \"#{now.to_date}\"", Rollup.last.inspect
  end

  # uses date in upsert, no time
  def test_upsert_date
    create_users
    User.rollup("Test")
    assert_match "'#{now.to_date}'", $sql.find { |s| s =~ /ON (CONFLICT|DUPLICATE KEY)/i }
  end
end
