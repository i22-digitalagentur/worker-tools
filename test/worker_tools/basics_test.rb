require 'test_helper'

describe WorkerTools::Basics do
  class Foo
    include WorkerTools::Basics
    wrappers
  end

  class Importer
    include WorkerTools::Basics

    wrappers :basics

    def model_class
      Import
    end

    def model_kind
      'foo'
    end

    def run; end
  end

  class Wrapper
    include WorkerTools::Basics

    wrappers :basics, :foo, :bar

    attr_accessor :steps

    def with_wrapper_foo(&block)
      block.yield
      steps.push 'foo'
    end

    def with_wrapper_bar(&block)
      block.yield
      steps.push 'bar'
    end

    def model_class
      Import
    end

    def model_kind
      'foo'
    end

    def run
      @steps = []
    end
  end

  it 'needs model class, model kind, and run to be defined' do
    importer = Foo.new

    err = assert_raises(StandardError) { importer.model_class }
    assert_includes err.message, 'model_class has to be defined'

    err = assert_raises(StandardError) { importer.model_kind }
    assert_includes err.message, 'model_kind has to be defined'

    err = assert_raises(StandardError) { importer.run }
    assert_includes err.message, 'run has to be defined'
  end

  describe '#model' do
    it 'retuns the model from id or instance' do
      import = create_import

      importer = Importer.new
      importer.perform(import)
      assert_equal import, importer.model

      importer = Importer.new
      importer.perform(import.id)
      assert_equal import, importer.model
    end

    it 'creates the model if not present' do
      importer = Importer.new
      import = importer.model
      assert_instance_of Import, import
    end
  end

  describe '#self.wrappers' do
    it 'calls the defined wrappers in order' do
      import = create_import
      importer = Wrapper.new
      importer.perform(import)
      assert_equal %w[bar foo], importer.steps
    end

    it 'raise an exception if a wrapper method is missing ' do
      import = create_import
      importer = Wrapper.new
      importer.instance_eval { undef :with_wrapper_foo }
      exception = assert_raises(StandardError) { importer.perform(import) }
      assert_equal 'Missing wrapper foo', exception.message
    end
  end

  describe '#perform' do
    it 'calls run and finalize if nothing goes wrong' do
      import = create_import
      importer = Importer.new

      importer.expects(:run)
      importer.expects(:finalize)
      importer.perform(import)
    end

    it 'calls run and saves the error and raises if it goes wrong' do
      import = create_import
      importer = Importer.new
      err_message = 'something wrong happened'
      importer.expects(:run).raises(StandardError, err_message)

      err = assert_raises(StandardError) { importer.perform(import) }
      assert_includes err.message, err_message
      assert import.failed?
    end

    it 'does not raise or mark as failed after a non failure error' do
      import = create_import
      importer = Importer.new
      importer.expects(:run).raises(WorkerTools::Errors::WrongNumberOfColumns)
      importer.perform(import)
      assert import.complete?
    end

    it 'sets the model to running state' do
      import = create_import
      importer = Importer.new
      importer.model = import
      importer.stubs(:finalize) # do not set it to complete
      importer.perform

      assert_equal(import.state, 'running')
    end
  end

  describe '#finalize' do
    it 'saves note into the model and sets the state to complete' do
      import = create_import
      importer = Importer.new
      importer.model = import
      note = { level: 'info', message: 'some message' }.with_indifferent_access
      importer.model.notes.push(note)

      importer.send(:finalize)
      assert import.complete?
      assert_equal [note], import.notes
    end

    it 'sets the state to complete_with_warnings if the notes contain errors or warnings' do
      import = create_import
      importer = Importer.new
      importer.model = import

      importer.model.notes = [{ level: :warning, message: 'pay attention to this' }]
      importer.send(:finalize)
      assert import.complete_with_warnings?

      import.state = :complete
      importer.model.notes = [{ level: :error, message: 'pay also attention to this' }]
      importer.send(:finalize)
      assert import.complete_with_warnings?
    end
  end
end
