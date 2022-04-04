module WorkerTools
  module Benchmark
    attr_accessor :benchmark

    def measure(&block)
      start = Time.zone.now
      bm = Benchmark.measure(&block)
      real = Time.zone.now - start
  
      if Rails.env.in? %w[production staging]
        bm.instance_variable_set(:@total, real)
        bm.instance_variable_set(:@real, real)
      end
  
      @benchmark = bm
    end
  end
end
