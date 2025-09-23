require 'test_helper'

describe WorkerTools::MemoryUsage do
  class MemoryUsageTest
    include WorkerTools::Basics
    include WorkerTools::MemoryUsage

    wrappers :basics, :memory_usage

    def model_class
      Import
    end

    def model_kind
      'memory_usage_test'
    end

    def run; end
  end

  describe '#with_wrapper_memory_usage' do
    before :each do
      @import = create_import
      @importer = MemoryUsageTest.new
    end

    it 'should measure memory usage and store in model meta' do
      # Mock GetProcessMem
      memory_mock = mock('memory')
      memory_mock.stubs(:mb).returns(100.0).then.returns(105.5)

      GetProcessMem.stubs(:new).returns(memory_mock)

      @importer.perform(@import)

      expect(@importer.model.meta['memory_usage']).must_equal 5.5
    end

    it 'should handle exceptions and still record memory usage' do
      # Mock GetProcessMem
      memory_mock = mock('memory')
      memory_mock.stubs(:mb).returns(50.0).then.returns(52.3)

      GetProcessMem.stubs(:new).returns(memory_mock)

      # Make run method raise an error
      def @importer.run
        raise StandardError, 'Test error'
      end

      assert_raises(StandardError) { @importer.perform(@import) }

      # Should still record memory usage
      expect(@importer.model.meta['memory_usage']).must_equal 2.3
    end

    it 'should round memory usage to 2 decimal places' do
      # Mock GetProcessMem
      memory_mock = mock('memory')
      memory_mock.stubs(:mb).returns(100.0).then.returns(100.123456)

      GetProcessMem.stubs(:new).returns(memory_mock)

      @importer.perform(@import)

      expect(@importer.model.meta['memory_usage']).must_equal 0.12
    end

    it 'should handle negative memory differences' do
      # Mock GetProcessMem - could happen due to measurement fluctuations
      memory_mock = mock('memory')
      memory_mock.stubs(:mb).returns(100.0).then.returns(99.5)

      GetProcessMem.stubs(:new).returns(memory_mock)

      @importer.perform(@import)

      expect(@importer.model.meta['memory_usage']).must_equal(-0.5)
    end

    it 'should not set memory_usage if model does not respond to meta' do
      # Mock a model without meta but with the necessary attributes for basics wrapper
      model_without_meta = mock('model')
      model_without_meta.stubs(:respond_to?).with(:meta).returns(false)
      model_without_meta.stubs(:attributes=)
      model_without_meta.stubs(:save!)
      model_without_meta.stubs(:state=)
      @importer.stubs(:model).returns(model_without_meta)

      # Mock GetProcessMem
      memory_mock = mock('memory')
      memory_mock.stubs(:mb).returns(100.0).then.returns(105.0)
      GetProcessMem.stubs(:new).returns(memory_mock)

      # Should not try to access meta since model doesn't respond to it
      model_without_meta.expects(:meta).never

      @importer.perform(@import)
    end
  end
end
