class Rollup
  module Utils
    DATE_INTERVALS = %w(day week month quarter year)

    class << self
      def time_sql(interval)
        if date_interval?(interval)
          if postgresql?
            "rollups.time::date"
          elsif sqlite?
            "date(rollups.time)"
          else
            "CAST(rollups.time AS date)"
          end
        else
          :time
        end
      end

      def date_interval?(interval)
        DATE_INTERVALS.include?(interval.to_s)
      end

      def dimensions_supported?
        unless defined?(@dimensions_supported)
          @dimensions_supported = postgresql? && Rollup.column_names.include?("dimensions")
        end
        @dimensions_supported
      end

      def check_dimensions
        raise "Dimensions not supported" unless dimensions_supported?
      end

      def adapter_name
        Rollup.connection.adapter_name
      end

      def postgresql?
        adapter_name =~ /postg/i
      end

      def mysql?
        adapter_name =~ /mysql|trilogy/i
      end

      def sqlite?
        adapter_name =~ /sqlite/i
      end

      def make_series(result, interval)
        series = {}
        if Utils.date_interval?(interval)
          result.each do |row|
            series[row[0].to_date] = row[1]
          end
        else
          time_zone = Rollup.time_zone
          if result.any? && result[0][0].is_a?(Time)
            result.each do |row|
              series[row[0].in_time_zone(time_zone)] = row[1]
            end
          else
            utc = ActiveSupport::TimeZone["Etc/UTC"]
            result.each do |row|
              # row can be time or string
              series[utc.parse(row[0]).in_time_zone(time_zone)] = row[1]
            end
          end
        end
        series
      end
    end
  end
end
