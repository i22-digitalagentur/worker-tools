require 'test_helper'

describe WorkerTools::CsvOutput do
  class Foo
    include WorkerTools::CsvOutput
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
    class FooCorrect
      include WorkerTools::CsvOutput

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
      assert File.exist?(@klass.csv_output_tmp_file.path)
      file = File.new(@klass.csv_output_tmp_file.path, encoding: Encoding::UTF_8)
      content = file.read
      file.close

      assert_equal "Col 1;Col 2\ncell_1.1ä;cell_1.2ü\ncell_2.1;cell_2.2\n", content
    end

    it 'successful writing of csv file with encoding ISO_8859_1' do
      @klass.stubs(:csv_output_encoding).returns(Encoding::ISO_8859_1)
      assert_equal Encoding::ISO_8859_1, @klass.csv_output_encoding

      @klass.csv_output_write_file
      assert File.exist?(@klass.csv_output_tmp_file.path)
      file = File.new(@klass.csv_output_tmp_file.path)
      content = file.read
      file.close

      assert_equal "Col 1;Col 2\ncell_1.1\xE4;cell_1.2\xFC\ncell_2.1;cell_2.2\n", content
    end

    it 'successful writing of csv file with custom file name' do
      @klass.stubs(:csv_output_target).returns('test.csv')
      assert @klass.csv_output_target

      @klass.csv_output_write_file
      assert File.exist?('test.csv')
      file = File.new(@klass.csv_output_tmp_file.path, encoding: Encoding::UTF_8)
      content = file.read
      file.close

      assert_equal "Col 1;Col 2\ncell_1.1ä;cell_1.2ü\ncell_2.1;cell_2.2\n", content
      FileUtils.rm('test.csv') # cleaning path
    end

    it 'successful writing of csv file with custom file name within given folder' do
      @klass.stubs(:csv_output_target).returns('foo/test.csv')
      assert @klass.csv_output_target

      @klass.csv_output_write_file
      assert File.exist?('foo/test.csv')
      file = File.new(@klass.csv_output_tmp_file.path, encoding: Encoding::UTF_8)
      content = file.read
      file.close

      assert_equal "Col 1;Col 2\ncell_1.1ä;cell_1.2ü\ncell_2.1;cell_2.2\n", content

      FileUtils.rm_rf('foo') # cleaning path
    end
  end
end
