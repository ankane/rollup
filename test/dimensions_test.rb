require_relative "test_helper"

class DimensionsTest < Minitest::Test
  def setup
    skip unless dimensions_supported?
    super
  end

  def test_string
    assert_dimension_name "browser", "browser"
  end

  def test_string_table
    assert_dimension_name "users.browser", "browser"
  end

  def test_string_quoted
    assert_dimension_name "\"browser\"", "browser"
  end

  def test_string_table_quoted
    assert_dimension_name "\"users\".\"browser\"", "browser"
  end

  def test_symbol
    assert_dimension_name :browser, "browser"
  end

  def test_json
    assert_dimension_name "properties -> 'browser'", "browser"
  end

  def test_json_text_operator
    assert_dimension_name "properties ->> 'browser'", "browser"
  end

  def test_unknown
    error = assert_raises do
      User.group("LOWER(browser)").rollup("Test")
    end
    assert_equal "Cannot determine dimension name: LOWER(browser). Use the dimension_names option", error.message
  end

  def test_dimension_names
    assert_dimension_name :browser, "hi", dimension_names: ["hi"]
  end

  def test_dimension_names_wrong_size
    error = assert_raises(ArgumentError) do
      User.group(:browser).rollup("Test", dimension_names: ["a", "b"])
    end
    assert_equal "Expected dimension_names to be size 1, not 2", error.message
  end

  def assert_dimension_name(group, expected, **options)
    User.create!(browser: "Firefox", properties: {browser: "Firefox"})
    User.group(group).rollup("Test", **options)
    assert_equal [expected], Rollup.last.dimensions.keys
  end
end
