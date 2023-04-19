module WorkerTools
  module Counters
    extend ActiveSupport::Concern

    included do
      def self.counters(*args)
        @counters ||= args.flatten
        add_counter_methods
      end

      def self.read_counters
        @counters || []
      end

      def self.add_counter_methods
        @counters.each do |name|
          # ex `inserts`
          define_method(name) { model.meta[name] }

          # ex `inserts=`
          define_method("#{name}=") { |value| model.meta[name] = value }

          # ex `increment_inserts`
          define_method("increment_#{name}") { |inc = 1| model.meta[name] += inc }
        end
      end

      def with_wrapper_counters(&block)
        reset_counters
        block.call
      end

      def reset_counters
        self.class.read_counters.each do |name|
          model.meta[name] = 0
        end
      end
    end
  end
end
