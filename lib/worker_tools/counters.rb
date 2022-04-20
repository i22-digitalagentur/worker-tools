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
          define_method name do
            model.meta[name]
          end
          define_method "#{name}=" do |value|
            model.meta[name] = value
          end
          define_method "increment_#{name}" do
            model.meta[name] += 1
          end
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
