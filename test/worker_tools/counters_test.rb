require 'test_helper'

describe WorkerTools::Counters do
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
      expect(@importer.class.read_counters).must_equal %i[foo bar]
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
        expect(@importer.respond_to?("increment_#{counter}")).must_equal true
      end
    end

    describe '#counters_increment' do
      it 'increments the counter by 1 by default' do
        @importer.class.read_counters.each do |counter|
          @importer.send("#{counter}=", 0)
          @importer.send("increment_#{counter}")
          expect(@importer.send(counter)).must_equal 1
        end
      end

      it 'increments the counter by the given amount' do
        @importer.class.read_counters.each do |counter|
          @importer.send("#{counter}=", 0)
          @importer.send("increment_#{counter}", 2)
          expect(@importer.send(counter)).must_equal 2
        end
      end
    end

    describe '#counter=' do
      it 'overwrites the current counter value' do
        @importer.class.read_counters.each do |counter|
          @importer.send("#{counter}=", 5)
          expect(@importer.send(counter)).must_equal 5
        end

        @importer.class.read_counters.each do |counter|
          @importer.send("#{counter}=", 2)
          expect(@importer.send(counter)).must_equal 2
        end
      end
    end

    describe '#counter' do
      it 'returns value of counter' do
        @importer.class.read_counters.each do |counter|
          @importer.send("#{counter}=", 2)
          expect(@importer.send(counter)).must_equal 2
        end
      end
    end
  end

  describe '#with_wrapper_counters' do
    before :each do
      @import = create_import
      @importer = Counter.new
    end

    it 'should call reset_counters function' do
      @importer.expects(:reset_counters).returns(true)
      @importer.perform(@import)
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
