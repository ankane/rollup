require_relative "test_helper"

class CalculationTest < Minitest::Test
  def test_count
    User.create!(created_at: now - 2.days)
    User.create!(created_at: now)
    User.create!(created_at: now)
    User.rollup("Test")
    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => 0,
      now.to_date => 2
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_sum
    User.create!(created_at: now - 2.days, visits: 1)
    User.create!(created_at: now, visits: 2)
    User.create!(created_at: now, visits: 3)
    User.rollup("Test") { |r| r.sum(:visits) }
    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => 0,
      now.to_date => 5
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_average
    User.create!(created_at: now - 2.days, visits: 1)
    User.create!(created_at: now, visits: 2)
    User.create!(created_at: now, visits: 3)
    User.rollup("Test") { |r| r.average(:visits) }
    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => nil,
      now.to_date => 2.5
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_minimum
    User.create!(created_at: now - 2.days, visits: 1)
    User.create!(created_at: now, visits: 2)
    User.create!(created_at: now, visits: 3)
    User.rollup("Test") { |r| r.minimum(:visits) }
    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => nil,
      now.to_date => 2
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_maximum
    User.create!(created_at: now - 2.days, visits: 1)
    User.create!(created_at: now, visits: 2)
    User.create!(created_at: now, visits: 3)
    User.rollup("Test") { |r| r.maximum(:visits) }
    expected = {
      now.to_date - 2 => 1,
      now.to_date - 1 => nil,
      now.to_date => 3
    }
    assert_equal expected, Rollup.series("Test")
  end

  def test_bad_type
    error = assert_raises do
      User.rollup("Test") { Object.new }
    end
    assert_equal "Expected calculation to return Hash, not Object", error.message
  end

  def test_bad_key_date
    error = assert_raises do
      User.rollup("Test") { {"non-date" => 1} }
    end
    assert_equal "Expected time to be Date, not String", error.message
  end

  def test_bad_key_time
    error = assert_raises do
      User.rollup("Test", interval: "hour") { {"non-time" => 1} }
    end
    assert_equal "Expected time to be Time, not String", error.message
  end

  def test_bad_key_type
    skip unless dimensions_supported?

    error = assert_raises do
      User.group(:browser).rollup("Test") { {Date.current => 1} }
    end
    assert_equal "Expected result key to be Array with size 2", error.message
  end

  def test_bad_key_size
    skip unless dimensions_supported?

    error = assert_raises do
      User.group(:browser).rollup("Test") { {[Date.current] => 1} }
    end
    assert_equal "Expected result key to be Array with size 2", error.message
  end

  def test_bad_value
    error = assert_raises do
      User.rollup("Test") { {Date.current => "string"} }
    end
    assert_equal "Expected value to be Numeric or nil, not String", error.message
  end
end
