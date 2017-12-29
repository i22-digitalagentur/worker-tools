require 'test_helper'

describe WorkerTools::Basics do
  class Foo
    include WorkerTools::Basics
  end

  class Importer
    include WorkerTools::Basics

    def model_class
      Import
    end

    def model_kind
      'foo'
    end

    def run; end
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

    it 'creates the model if create_model_if_not_available is set' do
      importer = Importer.new
      err = assert_raises(StandardError) { importer.model }
      assert_includes err.message, 'Model not available'

      importer = Importer.new
      importer.expects(:create_model_if_not_available).returns(true)
      import = importer.model
      assert_instance_of Import, import
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
  end
end
