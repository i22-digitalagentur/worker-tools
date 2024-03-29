require 'test_helper'

describe WorkerTools::Recorder do
  class ImporterWithRecorder
    include WorkerTools::Basics
    include WorkerTools::Recorder

    wrappers :basics, :recorder

    def model_class
      Import
    end

    def model_kind
      'foo/test'
    end

    def run; end
  end

  class StandAloneWithLogging
    include WorkerTools::Recorder

    def perform
      with_wrapper_logger do
        raise 'Some Error'
      end
    end
  end

  describe '#format_message' do
    before do
      @recorder = ImporterWithRecorder.new
      @exception = Exception.new('hello world')
    end

    describe 'with an Exception' do
      it 'invoke error_to_text method' do
        @recorder.expects(:error_to_text).returns('foo')
        @recorder.format_message(@exception)
      end

      it 'returns error message with backtrace' do
        @exception.stubs(:backtrace).returns(%w[foo hoo])

        expect(@recorder.format_message(@exception)).must_equal "Error: hello world (Exception)Backtrace:\nfoo\n\thoo"
      end
    end

    describe 'with an info message' do
      it 'returns message' do
        expect(@recorder.format_message('foo')).must_equal 'foo'
      end
    end
  end

  describe '#level_from_message_type' do
    before do
      @recorder = ImporterWithRecorder.new
    end

    describe 'with an Exception' do
      it 'returns :error' do
        exception = Exception.new('hello world')
        expect(@recorder.level_from_message_type(exception)).must_equal :error
      end
    end

    describe 'without an Exception' do
      it 'returns :info' do
        expect(@recorder.level_from_message_type('foo')).must_equal :info
      end
    end
  end

  describe '#default_message_attrs' do
    it 'returns an object with :message and :level' do
      recorder = ImporterWithRecorder.new
      expect(recorder.default_message_attrs('foo', :info)).must_equal(message: 'foo', level: :info)
    end
  end

  it 'basics#perform with record extension calls record_fail when exceptions' do
    import = create_import
    importer = ImporterWithRecorder.new
    err_message = 'something wrong happened'

    importer.expects(:run).raises(StandardError, err_message)
    importer.expects(:record_fail)

    assert_raises(StandardError) { importer.perform(import) }
  end

  it 'recording should modify note field of model and should create logging output' do
    import = create_import
    importer = ImporterWithRecorder.new
    exception = Exception.new('hello world')
    exception.stubs(:backtrace).returns(%w[foo hoo])
    log_path = test_tmp_path
    filename = 'importer_with_recorder.log'

    importer.stubs(:log_directory).returns(log_path)
    importer.perform(import)

    importer.record_fail(exception)
    assert_includes import.notes, 'level' => 'error', 'message' => "Error: hello world (Exception)Backtrace:\nfoo\n\thoo"

    log_content = File.open(File.join(log_path, filename)).read
    assert_includes log_content, 'hello world'
    assert_includes log_content, "Backtrace:\nfoo\n\thoo\n"
  end

  it 'should be possible to use the recorder in isolation without a model' do
    importer = StandAloneWithLogging.new
    log_path = test_tmp_path
    filename = 'stand_alone_with_logging.log'
    importer.stubs(:log_directory).returns(log_path)

    assert_raises(StandardError) { importer.perform }

    log_content = File.open(File.join(log_path, filename)).read
    assert_includes log_content, 'Some Error'
  end

  it 'makes sure that the directory exists' do
    importer = StandAloneWithLogging.new
    log_directory = File.join(test_tmp_path, 'foo')
    log_file_name = 'test.log'
    importer.stubs(:log_directory).returns(log_directory)
    importer.stubs(:log_file_name).returns(log_file_name)
    importer.add_log('something')

    log_content = File.read(File.join(log_directory, log_file_name))
    assert_includes log_content, 'something'
  end
end
