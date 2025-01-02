# Rollup

:fire: Rollup time-series data in Rails

Works great with [Ahoy](https://github.com/ankane/ahoy) and [Searchjoy](https://github.com/ankane/searchjoy)

[![Build Status](https://github.com/ankane/rollup/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/rollup/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "rollups"
```

And run:

```sh
bundle install
rails generate rollups
rails db:migrate
```

## Contents

- [Getting Started](#getting-started)
- [Creating Rollups](#creating-rollups)
- [Querying Rollups](#querying-rollups)
- [Other Topics](#other-topics)
- [Examples](#examples)

## Getting Started

Store the number of users created by day in the `rollups` table

```ruby
User.rollup("New users")
```

Get the series

```ruby
Rollup.series("New users")
# {
#   Wed, 01 Jan 2025 => 50,
#   Thu, 02 Jan 2025 => 100,
#   Fri, 03 Jan 2025 => 34
# }
```

Use a rake task or background job to create rollups on a regular basis. Don’t worry too much about naming - you can [rename](#naming) later if needed.

## Creating Rollups

### Time Column

Specify the time column - `created_at` by default

```ruby
User.rollup("New users", column: :joined_at)
```

Change the default column for a model

```ruby
class User < ApplicationRecord
  self.rollup_column = :joined_at
end
```

### Time Intervals

Specify the interval - `day` by default

```ruby
User.rollup("New users", interval: "week")
```

And when querying

```ruby
Rollup.series("New users", interval: "week")
```

Supported intervals are:

- hour
- day
- week
- month
- quarter
- year

Or any number of minutes or seconds:

- 1m, 5m, 15m
- 1s, 30s, 90s

Weeks start on Sunday by default. Change this with:

```ruby
Rollup.week_start = :monday
```

### Time Zones

The default time zone is `Time.zone`. Change this with:

```ruby
Rollup.time_zone = "Pacific Time (US & Canada)"
```

or

```ruby
User.rollup("New users", time_zone: "Pacific Time (US & Canada)")
```

Time zone objects also work. To see a list of available time zones in Rails, run `rake time:zones:all`.

See [date storage](#date-storage) for how dates are stored.

### Multiple Databases

Specify a `writing_role` when you want to explicitly switch the database role when writing the rollup to the database.

```ruby
Rollup.writing_role = :writing
```

See [ActiveRecord::Base.connected_to](https://guides.rubyonrails.org/active_record_multiple_databases.html#connecting-to-the-database) for more information.

### Calculations

Rollups use `count` by default. For other calculations, use:

```ruby
Order.rollup("Revenue") { |r| r.sum(:revenue) }
```

Works with `count`, `sum`, `minimum`, `maximum`, and `average`. For `median` and `percentile`, check out [ActiveMedian](https://github.com/ankane/active_median).

### Dimensions

*PostgreSQL only*

Create rollups with dimensions

```ruby
Order.group(:platform).rollup("Orders by platform")
```

Works with multiple groups as well

```ruby
Order.group(:platform, :channel).rollup("Orders by platform and channel")
```

Dimension names are determined by the `group` clause. To set manually, use:

```ruby
Order.group(:channel).rollup("Orders by source", dimension_names: ["source"])
```

See how to [query dimensions](#multiple-series).

### Updating Data

When you run a rollup for the first time, the entire series is calculated. When you run it again, newer data is added.

By default, the latest interval stored for a series is recalculated, since it was likely calculated before the interval completed. Earlier intervals aren’t recalculated since the source rows may have been deleted (this also improves performance).

To recalculate the last few intervals, use:

```ruby
User.rollup("New users", last: 3)
```

To recalculate a time range, use:

```ruby
User.rollup("New users", range: 1.week.ago.all_week)
```

To only store data for completed intervals, use:

```ruby
User.rollup("New users", current: false)
```

To clear and recalculate the entire series, use:

```ruby
User.rollup("New users", clear: true)
```

To delete a series, use:

```ruby
Rollup.where(name: "New users", interval: "day").delete_all
```

## Querying Rollups

### Single Series

Get a series

```ruby
Rollup.series("New users")
```

Specify the interval if it’s not day

```ruby
Rollup.series("New users", interval: "week")
```

If a series has dimensions, they must match exactly as well

```ruby
Rollup.series("Orders by platform and channel", dimensions: {platform: "Web", channel: "Search"})
```

Get a specific time range

```ruby
Rollup.where(time: Date.current.all_year).series("New Users")
```

### Multiple Series

*PostgreSQL only*

Get multiple series grouped by dimensions

```ruby
Rollup.multi_series("Orders by platform")
```

Specify the interval if it’s not day

```ruby
Rollup.multi_series("Orders by platform", interval: "week")
```

Filter by dimensions

```ruby
Rollup.where_dimensions(platform: "Web").multi_series("Orders by platform and channel")
```

Get a specific time range

```ruby
Rollup.where(time: Date.current.all_year).multi_series("Orders by platform")
```

### Raw Data

Uses the `Rollup` model to query the data directly

```ruby
Rollup.where(name: "New users", interval: "day")
```

### List

List names and intervals

```ruby
Rollup.list
```

### Charts

Rollup works great with [Chartkick](https://github.com/ankane/chartkick)

```erb
<%= line_chart Rollup.series("New users") %>
```

For multiple series, set a `name` for each series before charting

```ruby
series = Rollup.multi_series("Orders by platform")
series.each do |s|
  s[:name] = s[:dimensions]["platform"]
end
```

## Other Topics

### Naming

Use any naming convention you prefer. Some ideas are:

- Human - `New users`
- Underscore - `new_users`
- Dots - `new_users.count`

Rename with:

```ruby
Rollup.rename("Old name", "New name")
```

### Date Storage

Rollup stores both dates and times in the `time` column depending on the interval. For date intervals (day, week, etc), it stores `00:00:00` for the time part. Cast the `time` column to a date when querying in SQL to get the correct value.

- PostgreSQL: `time::date`
- MySQL: `CAST(time AS date)`
- SQLite: `date(time)`

## Examples

- [Ahoy](#ahoy)
- [Searchjoy](#searchjoy)

### Ahoy

Set the default rollup column for your models

```ruby
class Ahoy::Visit < ApplicationRecord
  self.rollup_column = :started_at
end
```

and

```ruby
class Ahoy::Event < ApplicationRecord
  self.rollup_column = :time
end
```

Hourly visits

```ruby
Ahoy::Visit.rollup("Visits", interval: "hour")
```

Visits by browser

```ruby
Ahoy::Visit.group(:browser).rollup("Visits by browser")
```

Unique homepage views

```ruby
Ahoy::Event.where(name: "Viewed homepage").joins(:visit).rollup("Homepage views") { |r| r.distinct.count(:visitor_token) }
```

Product views

```ruby
Ahoy::Event.where(name: "Viewed product").group_prop(:product_id).rollup("Product views")
```

### Searchjoy

Daily searches

```ruby
Searchjoy::Search.rollup("Searches")
```

Searches by query

```ruby
Searchjoy::Search.group(:normalized_query).rollup("Searches by query", dimension_names: ["query"])
```

Conversion rate

```ruby
Searchjoy::Search.rollup("Search conversion rate") { |r| r.average("(converted_at IS NOT NULL)::int") }
```

## History

View the [changelog](https://github.com/ankane/rollup/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/rollup/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/rollup/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/rollup.git
cd rollup
bundle install

# create databases
createdb rollup_test
mysqladmin create rollup_test

# run tests
bundle exec rake test
```
