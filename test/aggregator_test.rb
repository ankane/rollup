require_relative "test_helper"

class AggregatorTest < Minitest::Test
  def test_updates_latest
    create_users
    User.rollup("Test")

    create_users
    User.rollup("Test")

    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => 1,
      now.to_date => 2
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_clear
    create_users
    User.rollup("Test")

    create_users
    User.rollup("Test", clear: true)

    expected = {
      now.to_date - 2 => 2,
      now.to_date - 1 => 2,
      now.to_date => 2
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_last
    create_users
    User.rollup("Test")

    create_users
    User.rollup("Test", last: 2)

    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => 2,
      now.to_date => 2
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_last_clear
    error = assert_raises(ArgumentError) do
      User.rollup("Test", last: 2, clear: true)
    end
    assert_equal "Cannot use last and clear together", error.message
  end

  def test_last_range
    error = assert_raises(ArgumentError) do
      User.rollup("Test", last: 2, range: now.all_day)
    end
    assert_equal "Cannot use last and range together", error.message
  end

  def test_current
    create_users
    User.rollup("Test", current: false)

    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => 1
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_name_nil
    error = assert_raises do
      User.rollup(nil)
    end
    assert_equal error.message, "Name can't be blank"
  end

  def test_name_empty
    error = assert_raises do
      User.rollup("")
    end
    assert_equal error.message, "Name can't be blank"
  end

  def test_range
    create_users
    User.rollup("Test", range: (now - 1.day).all_day)

    expected = {
      now.to_date - 1 => 1
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_range_updates
    create_users
    User.rollup("Test")

    create_users
    User.rollup("Test", range: (now - 1.day).all_day)

    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => 2,
      now.to_date => 1
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_range_expanded
    create_users
    User.rollup("Test", range: now...now)

    expected = {
      now.to_date => 1
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_range_clear
    error = assert_raises(ArgumentError) do
      User.rollup("Test", range: now.all_day, clear: true)
    end
    assert_equal "Cannot use range and clear together", error.message
  end

  def test_range_current
    error = assert_raises(ArgumentError) do
      User.rollup("Test", range: now.all_day, current: false)
    end
    assert_equal "Cannot use range and current together", error.message
  end
end
