class Rollup < ActiveRecord::Base
  validates :name, presence: true
  validates :interval, presence: true
  validates :time, presence: true

  class << self
    attr_accessor :week_start
    attr_writer :time_zone
  end
  self.week_start = :sunday

  class << self
    # do not memoize so Time.zone can change
    def time_zone
      (defined?(@time_zone) && @time_zone) || Time.zone || "Etc/UTC"
    end

    def series(name, interval: "day", dimensions: {})
      Utils.check_dimensions if dimensions.any?

      relation = where(name: name, interval: interval)
      relation = relation.where(dimensions: dimensions) if Utils.dimensions_supported?

      # use select_all due to incorrect casting with pluck
      sql = relation.order(:time).select(Utils.time_sql(interval), :value).to_sql
      result = connection_pool.with_connection { |c| c.select_all(sql) }.rows

      Utils.make_series(result, interval)
    end

    def multi_series(name, interval: "day")
      Utils.check_dimensions

      relation = where(name: name, interval: interval)

      # use select_all to reduce allocations
      sql = relation.order(:time).select(Utils.time_sql(interval), :value, :dimensions).to_sql
      result = connection_pool.with_connection { |c| c.select_all(sql) }.rows

      result.group_by { |r| JSON.parse(r[2]) }.map do |dimensions, rollups|
        {dimensions: dimensions, data: Utils.make_series(rollups, interval)}
      end
    end

    def where_dimensions(dimensions)
      Utils.check_dimensions

      relation = self
      dimensions.each do |k, v|
        k = k.to_s
        relation =
          if v.nil?
            relation.where("dimensions ->> ? IS NULL", k)
          elsif v.is_a?(Array)
            relation.where("dimensions ->> ? IN (?)", k, v.map { |vi| vi.as_json.to_s })
          else
            relation.where("dimensions ->> ? = ?", k, v.as_json.to_s)
          end
      end
      relation
    end

    def list
      select(:name, :interval).distinct.order(:name, :interval).map do |r|
        {name: r.name, interval: r.interval}
      end
    end

    # TODO maybe use in_batches
    def rename(old_name, new_name)
      where(name: old_name).update_all(name: new_name)
    end
  end

  # feels cleaner than overriding _read_attribute
  def inspect
    if Utils.date_interval?(interval)
      super.sub(/time: "[^"]+"/, "time: \"#{time.to_formatted_s(:db)}\"")
    else
      super
    end
  end

  def time
    if Utils.date_interval?(interval) && !time_before_type_cast.nil?
      if time_before_type_cast.is_a?(Time)
        time_before_type_cast.utc.to_date
      else
        Date.parse(time_before_type_cast.to_s)
      end
    else
      super
    end
  end
end
