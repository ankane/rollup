require_relative "test_helper"

class IntervalTest < Minitest::Test
  def test_1s
    assert_interval "1s"
  end

  def test_30s
    assert_interval "30s"
  end

  def test_1m
    assert_interval "1m"
  end

  def test_5m
    assert_interval "5m"
  end

  def test_hour
    assert_interval "hour"
  end

  def test_day
    assert_interval "day"
  end

  def test_week
    assert_interval "week"
  end

  def test_month
    assert_interval "month"
  end

  def test_quarter
    skip "Not supported by Groupdate" if sqlite?

    assert_interval "quarter"
  end

  def test_year
    assert_interval "year"
  end

  def test_bad
    error = assert_raises(ArgumentError) do
      User.rollup("Test", interval: "bad")
    end
    assert_equal "Invalid interval: bad", error.message
  end

  def assert_interval(interval)
    create_users(interval: interval)
    User.rollup("Test", interval: interval)

    assert [interval]*3, Rollup.pluck(:interval)

    start =
      case interval
      when "1s"
        now.change(nsec: 0)
      when "30s"
        Time.at(now.to_i / 30 * 30)
      when "1m"
        now.change(sec: 0)
      when "5m"
        Time.at(now.to_i / 5.minutes * 5.minutes)
      when "week"
        now.beginning_of_week(:sunday)
      else
        now.send("beginning_of_#{interval}")
      end

    step = interval_step(interval)

    expected = {}
    3.times do |i|
      k = start.dup
      # need to go one step at a time
      i.times do
        k -= step
      end
      k = k.to_date if %w(day week month quarter year).include?(interval)
      expected[k] = 1
    end
    assert_equal expected, Rollup.series("Test", interval: interval)
  end
end
