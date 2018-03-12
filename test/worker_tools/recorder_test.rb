require 'test_helper'

describe WorkerTools::Recorder do
  class ImporterWithRecorder
    include WorkerTools::Basics
    include WorkerTools::Recorder

    wrappers :basics, :recording

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

  it 'basics#perform with record extension calls record_fail when exceptions' do
    import = create_import
    importer = ImporterWithRecorder.new
    err_message = 'something wrong happened'

    importer.expects(:run).raises(StandardError, err_message)
    importer.expects(:record_fail)

    assert_raises(StandardError) { importer.perform(import) }
  end

  it 'recording should modify information field of model and shoul create logging output' do
    import = create_import
    importer = ImporterWithRecorder.new
    exception = Exception.new('hello world')
    exception.stubs(:backtrace).returns(%w[foo hoo])
    log_path = test_tmp_path
    filename = 'importer_with_recorder.log'

    importer.stubs(:log_directory).returns(log_path)
    importer.perform(import)

    importer.record_fail(exception)

    assert_includes import.information, 'hello world'
    assert_includes import.information, "Backtrace:\nfoo\n\thoo\n"

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
end
