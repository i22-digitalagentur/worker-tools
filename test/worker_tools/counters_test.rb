require 'test_helper'

describe WorkerTools::Counters do
  class Foo
    include WorkerTools::Basics
    wrappers
  end

  class Counter
    include WorkerTools::Basics
    include WorkerTools::Counters

    wrappers :basics, :counters
    counters :foo, :bar

    def model_class
      Import
    end

    def model_kind
      'foo'
    end

    def run; end
  end

  describe '#counters' do
    before :each do
      import = create_import
      @importer = Counter.new
      @importer.perform(import)
    end

    it 'returns an array of counters' do
      expect(@importer.class.read_counters).must_equal [:foo, :bar]
    end

    it 'creates for each counter a getter method' do
      @importer.class.read_counters.each do |counter|
        expect(@importer.respond_to?(counter)).must_equal true
      end
    end

    it 'creates for each counter a setter method' do
      @importer.class.read_counters.each do |counter|
        expect(@importer.respond_to?("#{counter}=")).must_equal true
      end
    end

    it 'creates for each counter an incrementer method' do
      @importer.class.read_counters.each do |counter|
        expect(@importer.respond_to?("increment_#{counter}=")).must_equal true
      end
    end
  end

  describe '#with_wrapper_counters' do
    before :each do
      @import = create_import
    end

    it 'should call reset_counters function' do
      mocked_reset_counters = MiniTest::Mock.new
      mocked_reset_counters.expect :call, nil
      some_instance = Counter.new
      some_instance.stub :reset_counters, mocked_reset_counters do
        some_instance.reset_counters
      end
      some_instance.perform(@import)
      # some_instance.verify
    end

    it 'raise error if model.meta not exist' do
      importer = Counter.new
      err = assert_raises(StandardError) { importer.with_wrapper_counters }
      assert_includes err.message, 'Model not available'
    end
  end

  describe 'reset_counters' do
    before :each do
      import = create_import
      @importer = Counter.new
      @importer.perform(import)
    end

    it 'resets the counters' do
      @importer.class.read_counters.each do |counter|
        @importer.send("#{counter}=", 1)
        expect(@importer.send(counter)).must_equal 1
      end

      @importer.reset_counters

      @importer.class.read_counters.each do |counter|
        expect(@importer.send(counter)).must_equal 0
      end
    end
  end
end
