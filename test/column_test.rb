require_relative "test_helper"

class ColumnTest < Minitest::Test
  def test_string
    User.rollup("Test", column: "created_at")
  end

  def test_string_table
    User.rollup("Test", column: "users.created_at")
  end

  def test_symbol
    User.rollup("Test", column: :created_at)
  end

  def test_symbol_missing
    # for sqlite, double-quoted string literals are accepted
    # https://www.sqlite.org/quirks.html
    if sqlite?
      User.rollup("Test", column: :missing)
      assert_equal 0, Rollup.count
    else
      assert_raises do
        User.rollup("Test", column: :missing)
      end
    end
  end

  def test_symbol_quoted
    User.rollup("Test", column: :missing) rescue nil
    sql = $sql.last
    quoted_name = User.connection.quote_column_name("missing")
    refute_equal quoted_name, "missing"
    assert_match quoted_name, sql
    # important: makes sure all instances are quoted
    assert_equal sql.split(/[^_]missing/).size, sql.split(quoted_name).size
  end

  def test_arel
    User.rollup("Test", column: Arel.sql("(created_at)"))
  end

  def test_no_arel
    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      User.rollup("Test", column: "(created_at)")
    end
    assert_equal "Query method called with non-attribute argument(s): \"(created_at)\". Use Arel.sql() for known-safe values.", error.message
  end

  def test_rollup_column
    Post.create!
    Post.rollup("Test")
  end

  def test_joins
    user = User.create!(created_at: now - 2.days)
    user.posts.create!
    user.posts.create!

    user2 = User.create!(created_at: now - 1.days)
    user2.posts.create!

    User.create!(created_at: now)

    Post.joins(:user).rollup("Test", column: "users.created_at")

    expected = {
      now.to_date - 2 => 2,
      now.to_date - 1 => 1
    }
    assert_equal expected, Rollup.series("Test")
  end
end
