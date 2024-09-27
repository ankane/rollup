class Rollup
  class Aggregator
    def initialize(klass)
      @klass = klass # or relation
    end

    def rollup(name, column: nil, interval: "day", dimension_names: nil, time_zone: nil, current: nil, last: nil, clear: false, range: nil, &block)
      raise "Name can't be blank" if name.blank?

      column ||= @klass.rollup_column || :created_at
      # Groupdate 6+ validates, but keep this for now for additional safety
      # no need to quote/resolve column here, as Groupdate handles it
      column = validate_column(column)

      relation = perform_group(name, column: column, interval: interval, time_zone: time_zone, current: current, last: last, clear: clear, range: range)
      result = perform_calculation(relation, &block)

      dimension_names = set_dimension_names(dimension_names, relation)
      records = prepare_result(result, name, dimension_names, interval)

      maybe_clear(clear, name, interval) do
        save_records(records) if records.any?
      end
    end

    # basic version of Active Record disallow_raw_sql!
    # symbol = column (safe), Arel node = SQL (safe), other = untrusted
    # matches table.column and column
    def validate_column(column)
      unless column.is_a?(Symbol) || column.is_a?(Arel::Nodes::SqlLiteral)
        column = column.to_s
        unless /\A\w+(\.\w+)?\z/i.match?(column)
          raise ActiveRecord::UnknownAttributeReference, "Query method called with non-attribute argument(s): #{column.inspect}. Use Arel.sql() for known-safe values."
        end
      end
      column
    end

    def perform_group(name, column:, interval:, time_zone:, current:, last:, clear:, range:)
      raise ArgumentError, "Cannot use last and range together" if last && range
      raise ArgumentError, "Cannot use last and clear together" if last && clear
      raise ArgumentError, "Cannot use range and clear together" if range && clear
      raise ArgumentError, "Cannot use range and current together" if range && !current.nil?

      current = true if current.nil?
      time_zone = Rollup.time_zone if time_zone.nil?

      gd_options = {
        current: current
      }

      # make sure Groupdate global options aren't applied
      gd_options[:time_zone] = time_zone
      gd_options[:week_start] = Rollup.week_start if interval.to_s == "week"
      gd_options[:day_start] = 0 if Utils.date_interval?(interval)

      if last
        gd_options[:last] = last
      elsif range
        gd_options[:range] = range
        gd_options[:expand_range] = true
        gd_options.delete(:current)
      elsif !clear
        # if no rollups, compute all intervals
        # if rollups, recompute last interval
        max_time = Rollup.unscoped.where(name: name, interval: interval).maximum(Utils.time_sql(interval))
        if max_time
          # for MySQL on Ubuntu 18.04 (and likely other platforms)
          if max_time.is_a?(String)
            utc = ActiveSupport::TimeZone["Etc/UTC"]
            max_time =
              if Utils.date_interval?(interval)
                max_time.to_date
              else
                t = utc.parse(max_time)
                t = t.in_time_zone(time_zone) if time_zone
                t
              end
          end

          # aligns perfectly if time zone doesn't change
          # if time zone does change, there are other problems besides this
          gd_options[:range] = max_time..
        end
      end

      # intervals are stored as given
      # we don't normalize intervals (i.e. change 60s -> 1m)
      case interval.to_s
      when "hour", "day", "week", "month", "quarter", "year"
        @klass.group_by_period(interval, column, **gd_options)
      when /\A\d+s\z/
        @klass.group_by_second(column, n: interval.to_i, **gd_options)
      when /\A\d+m\z/
        @klass.group_by_minute(column, n: interval.to_i, **gd_options)
      else
        raise ArgumentError, "Invalid interval: #{interval}"
      end
    end

    def set_dimension_names(dimension_names, relation)
      groups = relation.group_values[0..-2]

      if dimension_names
        Utils.check_dimensions
        if dimension_names.size != groups.size
          raise ArgumentError, "Expected dimension_names to be size #{groups.size}, not #{dimension_names.size}"
        end
        dimension_names
      else
        Utils.check_dimensions if groups.any?
        groups.map { |group| determine_dimension_name(group) }
      end
    end

    def determine_dimension_name(group)
      # split by ., ->>, and -> and remove whitespace
      value = group.to_s.split(/\s*((\.)|(->>)|(->))\s*/).last

      # removing starting and ending quotes
      # for simplicity, they don't need to be the same
      value = value[1..-2] if value.match?(/\A["'`].+["'`]\z/)

      unless value.match?(/\A\w+\z/)
        raise "Cannot determine dimension name: #{group}. Use the dimension_names option"
      end

      value
    end

    # calculation can mutate relation, but that's fine
    def perform_calculation(relation, &block)
      if block_given?
        yield(relation)
      else
        relation.count
      end
    end

    def prepare_result(result, name, dimension_names, interval)
      raise "Expected calculation to return Hash, not #{result.class.name}" unless result.is_a?(Hash)

      time_class = Utils.date_interval?(interval) ? Date : Time
      dimensions_supported = Utils.dimensions_supported?
      expected_key_size = dimension_names.size + 1

      result.map do |key, value|
        dimensions = {}
        if dimensions_supported && dimension_names.any?
          unless key.is_a?(Array) && key.size == expected_key_size
            raise "Expected result key to be Array with size #{expected_key_size}"
          end
          time = key[-1]
          # may be able to support dimensions in SQLite by sorting dimension names
          dimension_names.each_with_index do |dn, i|
            dimensions[dn] = key[i]
          end
        else
          time = key
        end

        raise "Expected time to be #{time_class.name}, not #{time.class.name}" unless time.is_a?(time_class)
        raise "Expected value to be Numeric or nil, not #{value.class.name}" unless value.is_a?(Numeric) || value.nil?

        record = {
          name: name,
          interval: interval,
          time: time,
          value: value
        }
        record[:dimensions] = dimensions if dimensions_supported
        record
      end
    end

    def maybe_clear(clear, name, interval)
      if clear
        Rollup.transaction do
          Rollup.unscoped.where(name: name, interval: interval).delete_all
          yield
        end
      else
        yield
      end
    end

    def save_records(records)
      # order must match unique index
      # consider using index name instead
      conflict_target = [:name, :interval, :time]
      conflict_target << :dimensions if Utils.dimensions_supported?

      options = Utils.mysql? ? {} : {unique_by: conflict_target}
      if ActiveRecord::VERSION::MAJOR >= 8
        utc = ActiveSupport::TimeZone["Etc/UTC"]
        records.each do |v|
          v[:time] = v[:time].in_time_zone(utc) if v[:time].is_a?(Date)
        end
      end
      Rollup.unscoped.upsert_all(records, **options)
    end
  end
end
