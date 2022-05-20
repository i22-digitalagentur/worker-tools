module WorkerTools
  module Benchmark
    extend ActiveSupport::Concern

    included do
      attr_accessor :benchmark

      def with_wrapper_benchmark(&block)
        @benchmark = ::Benchmark.measure(&block)

        model.meta['duration'] = @benchmark.real.round if model.respond_to?(:meta)
      end
    end
  end
end
