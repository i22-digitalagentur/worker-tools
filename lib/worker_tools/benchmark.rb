module WorkerTools
  module Benchmark
    extend ActiveSupport::Concern

    included do
      attr_accessor :benchmark

      def with_wrapper_benchmark(&block)
        benchmark = ::Benchmark.measure do
          block.call
        rescue StandardError => e
          @benchmark_error = e
        end

        model.meta['duration'] = benchmark.real.round if model.respond_to?(:meta)
        raise @benchmark_error if @benchmark_error
      end
    end
  end
end
