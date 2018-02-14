require 'test_helper'

describe WorkerTools::Recorder do
  class ImporterWithRecorder
    include WorkerTools::Basics
    include WorkerTools::Recorder

    def model_class
      Import
    end

    def model_kind
      'foo/test'
    end

    def run; end
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
    exception.stubs(:backtrace).returns(['foo', 'hoo'])

    log_path = Gem::Specification.find_by_name('worker_tools').gem_dir
    filename = "/foo_test_#{importer.model_class.name.underscore.tr('/', '_')}.log"

    importer.stubs(:log_directory).returns(log_path)
    importer.perform(import)

    importer.record_fail(exception)

    assert_includes import.information, "hello world"
    assert_includes import.information, "Backtrace:\nfoo\n\thoo\n"

    f = File.new(log_path + filename).read
    assert_includes f, "hello world"
    assert_includes f, "Backtrace:\nfoo\n\thoo\n"

    FileUtils.rm(Gem::Specification.find_by_name('worker_tools').gem_dir + filename)
  end
end
