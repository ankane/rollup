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

  def test_writing_role_switching
    connected_to_args = nil
    ActiveRecord::Base.singleton_class.define_method(:connected_to) do |role:, &block|
      connected_to_args = role
      block.call
    end

    create_users
    Rollup.writing_role = :writing
    User.rollup("Test")

    assert_equal :writing, connected_to_args, "Expected connected_to to be called with writing role"
  ensure
    ActiveRecord::Base.singleton_class.remove_method(:connected_to)
    Rollup.writing_role = nil
  end

  def test_no_writing_role_switching
    connected_to_called = false
    ActiveRecord::Base.singleton_class.define_method(:connected_to) do |role:, &block|
      connected_to_called = true
      block.call
    end

    create_users
    Rollup.writing_role = nil
    User.rollup("Test")

    refute connected_to_called, "Expected connected_to not to be called when writing_role is nil"
  ensure
    ActiveRecord::Base.singleton_class.remove_method(:connected_to)
  end
end
