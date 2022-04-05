module WorkerTools
  module Benchmark
    attr_accessor :benchmark

    def with_wrapper_benchmark(&block)
      @benchmark = Benchmark.measure(&block)
  
      model.duration = @benchmark.real.round if model.responds_to?(:duration=)
    end
  end
end
