require 'test_helper'

describe WorkerTools::CsvOutput do
  class Foo
    include WorkerTools::Basics
    include WorkerTools::CsvOutput

    wrappers :basics

    def model_class
      Import
    end

    def model_kind
      'foo_test'
    end

    def create_model_if_not_available
      true
    end
  end

  it 'needs csv_output_column_headers to be defined' do
    klass = Foo.new
    err = assert_raises(RuntimeError) { klass.csv_output_column_headers }
    assert_includes err.message, 'csv_output_column_headers has to be defined in'
  end

  it 'needs csv_output_entries to be defined' do
    klass = Foo.new
    err = assert_raises(RuntimeError) { klass.csv_output_entries }
    assert_includes err.message, 'csv_output_entries has to be defined in'
  end

  it 'needs csv_output_row_values(arg) to be defined' do
    klass = Foo.new
    err = assert_raises(RuntimeError) { klass.csv_output_row_values(1) }
    assert_includes err.message, 'csv_output_row_values has to be defined in'
  end

  describe 'csv file output' do
    class FooCorrect < Foo
      def csv_output_column_headers
        {
          col_1: 'Col 1',
          col_2: 'Col 2'
        }
      end

      def csv_output_entries
        [
          {
            col_1: 'cell_1.1ä',
            col_2: 'cell_1.2ü',
            col_3: 'cell_1.3'
          },
          {
            col_1: 'cell_2.1',
            col_2: 'cell_2.2',
            col_3: 'cell_2.3'
          }
        ]
      end

      def csv_output_row_values(entry)
        entry.values_at(*csv_output_column_headers.keys)
      end
    end

    def setup
      @klass = FooCorrect.new
    end

    it 'no method definition raises and methods are well defined' do
      assert @klass.csv_output_column_headers
      assert @klass.csv_output_entries
      assert @klass.csv_output_row_values(@klass.csv_output_entries.first)
    end

    it 'csv_output_insert_headers should add all headers to csv' do
      csv = []
      assert_equal [['Col 1', 'Col 2']], @klass.csv_output_insert_headers(csv)
    end

    it 'csv_output_row_values should return only targeted values' do
      assert_equal %w[cell_1.1ä cell_1.2ü], @klass.csv_output_row_values(@klass.csv_output_entries.first)
      assert_equal %w[cell_2.1 cell_2.2], @klass.csv_output_row_values(@klass.csv_output_entries.second)
    end

    it 'successful writing of csv file' do
      @klass.csv_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      assert_instance_of Tempfile, attachment.file
      assert_equal 'foo_test.csv', attachment.file_name
      assert_equal 'text/csv', attachment.content_type
      assert_equal "Col 1;Col 2\ncell_1.1ä;cell_1.2ü\ncell_2.1;cell_2.2\n", attachment.file.read
    end

    it 'successful writing of csv file with encoding ISO_8859_1' do
      @klass.stubs(:csv_output_encoding).returns(Encoding::ISO_8859_1)
      @klass.csv_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      assert_equal "Col 1;Col 2\ncell_1.1\xE4;cell_1.2\xFC\ncell_2.1;cell_2.2\n", attachment.file.read
    end

    it 'successful writing of csv file with custom file name' do
      @klass.csv_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      assert_equal "Col 1;Col 2\ncell_1.1ä;cell_1.2ü\ncell_2.1;cell_2.2\n", attachment.file.read
    end

    it 'successful writing of csv file with custom file name within given folder' do
      @klass.csv_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      assert_equal "Col 1;Col 2\ncell_1.1ä;cell_1.2ü\ncell_2.1;cell_2.2\n", attachment.file.read
    end
  end

  describe '#csv_output_write_mode' do
    it 'sets the csv write mode' do
      klass = Foo.new
      klass.expects(:csv_output_write_mode).returns('write mode')
      CSV.expects(:open).with(anything, 'write mode', anything)

      klass.csv_output_write_file
    end
  end

  describe '#csv_output_csv_options' do
    it 'sets col_sep and encoding' do
      klass = Foo.new
      klass.expects(:csv_output_col_sep).returns('col sep')
      klass.expects(:csv_output_encoding).returns('encoding')
      CSV.expects(:open).with(anything, anything, col_sep: 'col sep', encoding: 'encoding')

      klass.csv_output_write_file
    end

    it 'sets the csv open options' do
      klass = Foo.new
      klass.expects(:csv_output_csv_options).returns(some: :options)
      CSV.expects(:open).with(anything, anything, some: :options)

      klass.csv_output_write_file
    end
  end
end
