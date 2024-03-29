require 'test_helper'

describe WorkerTools::Benchmark do
  class BenchmarkTest
    include WorkerTools::Basics
    include WorkerTools::Benchmark

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
      @importer = BenchmarkTest.new
      ::Benchmark.expects(:measure).returns(stub(real: 2))
    end

    it 'should call benchmark.measure function' do
      @importer.perform(@import)
    end

    it 'should assign value to model.meta[duration]' do
      @importer.perform(@import)
      expect(@importer.model.meta['duration']).must_equal 2
    end

    it 'assigns the duration even if the block fails' do
      def @importer.run
        sleep 1
        raise StandardError
      end

      ::Benchmark.unstub(:measure)

      assert_raises(StandardError) { @importer.perform(@import) }
      expect(@importer.model.meta['duration'] >= 1).must_equal true

      # it does not raise on a second perform

      def @importer.run
        true
      end

      @importer.perform(@import)
    end
  end
end
