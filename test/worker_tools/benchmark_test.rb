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
      @importer = CustomBenchmark.new
      Benchmark.expects(:measure).returns(stub(:real => 2))
    end

    it 'should call benchmark.measure function' do
      @importer.perform(@import)
    end

    it 'should assign value to model.meta[duration]' do
      @importer.perform(@import)
      expect(@importer.model.meta['duration']).must_equal 2
    end

    it 'raise error if model.meta not exist' do
      err = assert_raises(StandardError) { @importer.with_wrapper_benchmark }
      assert_includes err.message, 'Model not available'
    end
  end
end
