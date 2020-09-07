class Rollup
  module Model
    attr_accessor :rollup_column

    def rollup(*args, **options, &block)
      Aggregator.new(self).rollup(*args, **options, &block)
      nil
    end
  end
end
