require 'test_helper'

describe WorkerTools::CustomBenchmark do
  class CustomBenchmark
    include WorkerTools::Basics
    include WorkerTools::CustomBenchmark

    wrappers :basics, :benchmark

    def model_class
      Import
    end

    def model_kind
      'foo'
    end

    def run; end
  end

  describe '#with_wrapper_benchmark' do
    before :each do
      @import = create_import
      @some_instance = CustomBenchmark.new
      Benchmark.expects(:measure).returns(stub(:real => 2))
    end

    it 'should call benchmark.measure function' do
      @some_instance.perform(@import)
    end

    it 'should assign value to model.meta[duration]' do
      @some_instance.perform(@import)
      expect(@some_instance.model.meta['duration']).must_equal 2
    end
  end
end
