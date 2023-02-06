require_relative "test_helper"

class QueryTest < Minitest::Test
  def test_series
    create_users
    User.rollup("Test")
    expected = {}
    3.times do |i|
      expected[now.to_date - i] = 1
    end
    assert_equal expected, Rollup.series("Test")
    assert_empty Rollup.series("Test", interval: "week")
  end

  def test_series_where
    create_users
    User.rollup("Test")
    expected = {now.to_date - 1 => 1}
    range = (now.to_date - 1)...now.to_date
    assert_equal expected, Rollup.where(time: range).series("Test")
  end

  def test_series_missing
    assert_empty Rollup.series("Test")
  end

  def test_multi_series_no_dimensions
    skip unless dimensions_supported?

    create_users
    User.rollup("Test")
    data = {}
    3.times do |i|
      data[now.to_date - i] = 1
    end
    expected = [{dimensions: {}, data: data}]
    assert_equal expected, Rollup.multi_series("Test")
  end

  def test_multi_series_one_dimension
    skip unless dimensions_supported?

    browsers = %w(Firefox Firefox Brave)
    create_users(browser: browsers)
    User.group(:browser).rollup("Test")

    brave_data = {}
    firefox_data = {}
    3.times do |i|
      brave_data[now.to_date - i] = browsers[i] == "Brave" ? 1 : 0
      firefox_data[now.to_date - i] = browsers[i] == "Firefox" ? 1 : 0
    end
    expected = [
      {dimensions: {"browser" => "Brave"}, data: brave_data},
      {dimensions: {"browser" => "Firefox"}, data: firefox_data}
    ]
    assert_equal expected, Rollup.multi_series("Test").sort_by { |s| s[:dimensions]["browser"] }
  end

  def test_multi_series_many_dimensions
    skip unless dimensions_supported?

    browsers = %w(Firefox Firefox Brave)
    oses = %w(Mac Linux Linux)
    create_users(browser: browsers, os: oses)
    User.group(:browser, :os).rollup("Test")

    brave_linux_data = {}
    firefox_linux_data = {}
    firefox_mac_data = {}
    3.times do |i|
      brave_linux_data[now.to_date - i] = browsers[i] == "Brave" && oses[i] == "Linux" ? 1 : 0
      firefox_linux_data[now.to_date - i] = browsers[i] == "Firefox" && oses[i] == "Linux" ? 1 : 0
      firefox_mac_data[now.to_date - i] = browsers[i] == "Firefox" && oses[i] == "Mac" ? 1 : 0
    end
    expected = [
      {dimensions: {"browser" => "Brave", "os" => "Linux"}, data: brave_linux_data},
      {dimensions: {"browser" => "Firefox", "os" => "Linux"}, data: firefox_linux_data},
      {dimensions: {"browser" => "Firefox", "os" => "Mac"}, data: firefox_mac_data}
    ]
    assert_equal expected, Rollup.multi_series("Test").sort_by { |s| [s[:dimensions]["browser"], s[:dimensions]["os"]] }
  end

  def test_multi_series_dimensions_numeric
    skip unless dimensions_supported?

    visits = [3, 3, 5]
    create_users(visits: visits)
    User.group(:visits).rollup("Test")

    three_data = {}
    five_data = {}
    3.times do |i|
      three_data[now.to_date - i] = visits[i] == 3 ? 1 : 0
      five_data[now.to_date - i] = visits[i] == 5 ? 1 : 0
    end
    expected = [
      {dimensions: {"visits" => 3}, data: three_data},
      {dimensions: {"visits" => 5}, data: five_data}
    ]
    assert_equal expected, Rollup.multi_series("Test").sort_by { |s| s[:dimensions]["visits"] }
  end

  def test_multi_series_missing
    skip unless dimensions_supported?

    assert_empty Rollup.multi_series("Test")
  end

  def test_where_dimensions
    skip unless dimensions_supported?

    browsers = %w(Firefox Firefox Brave)
    oses = %w(Mac Linux Linux)
    visits = [3, 3, 5]
    create_users(browser: browsers, os: oses, visits: visits)
    User.group(:browser, :os, :visits).rollup("Test")

    assert_equal 2, Rollup.where_dimensions(browser: "Firefox").sum(:value)
    assert_equal 3, Rollup.where_dimensions(browser: ["Firefox", "Brave"]).sum(:value)
    assert_equal 1, Rollup.where_dimensions(browser: "Brave").sum(:value)
    assert_equal 1, Rollup.where_dimensions(browser: "Brave", os: "Linux").sum(:value)
    assert_equal 0, Rollup.where_dimensions(browser: "Brave", os: "Mac").sum(:value)
    assert_equal 2, Rollup.where_dimensions(visits: 3).sum(:value)
    assert_equal 3, Rollup.where_dimensions(visits: [3, 5]).sum(:value)
  end

  def test_list
    create_users
    User.rollup("Test A")
    User.rollup("Test B", interval: "week")
    User.rollup("Test C")
    expected = [
      {name: "Test A", interval: "day"},
      {name: "Test B", interval: "week"},
      {name: "Test C", interval: "day"}
    ]
    assert_equal expected, Rollup.list
  end
end
