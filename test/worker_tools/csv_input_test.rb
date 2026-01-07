require 'test_helper'

describe WorkerTools::CsvInput do
  class FooWithoutCsvInputColumns
    include WorkerTools::CsvInput
  end

  class FooWithoutHeaders
    include WorkerTools::CsvInput

    def csv_input_columns
      %w[col_1 col_2 col_3]
    end

    def csv_input_headers_present
      false
    end
  end

  class Foo
    include WorkerTools::CsvInput

    def csv_input_columns
      {
        col_1: 'Col 1',
        col_3: 'Col 3'
      }
    end
  end

  def setup
    @klass = Foo.new
  end

  it 'raises an error if csv_input_columns are not defined' do
    err = assert_raises(StandardError) { FooWithoutCsvInputColumns.new.csv_input_columns }
    assert_includes err.message, 'csv_input_columns has to be defined in'
  end

  describe '#csv_input_header_normalized' do
    it 'should remove leading and trailing spaces' do
      assert_equal 'hallo', @klass.csv_input_header_normalized("  \thallo \n\t   \t")
    end

    it 'should return string' do
      assert_equal '', @klass.csv_input_header_normalized(nil)
      assert_equal '6', @klass.csv_input_header_normalized(6)
      assert_equal '6.66', @klass.csv_input_header_normalized(6.66)
    end

    it 'should downcase unless csv_input_header_normalize? set to false' do
      assert_equal 'hallo', @klass.csv_input_header_normalized('HaLLo')
      @klass.stubs(:csv_input_header_normalize?).returns(false)
      assert_equal 'HaLLo', @klass.csv_input_header_normalized('HaLLo')
    end
  end

  describe '#cvs_input_value_cleanup' do
    it 'should remove leading and trailing spaces for strings' do
      assert_equal 'hallo', @klass.cvs_input_value_cleanup("  \thallo \n\t   \t")
    end

    it 'should not cast type' do
      assert @klass.cvs_input_value_cleanup("  \thallo \n\t   \t").is_a? String
      assert @klass.cvs_input_value_cleanup(6).is_a? Integer
      assert @klass.cvs_input_value_cleanup(6.66).is_a? Float
    end
  end

  describe '#csv_input_columns_check' do
    describe 'csv_input_columns is an array' do
      it 'raises a WrongNumberOfColumns error if the number of columns differ' do
        @klass.stubs(:csv_input_columns).returns(%w[foo])
        csv_enum = [%w[foo foo2], %w[test test2]]
        err = assert_raises(WorkerTools::Errors::WrongNumberOfColumns) { @klass.csv_input_columns_check(csv_enum) }
        assert_includes err.message, 'The number of columns'
      end

      it 'successfully checks the amount of columns' do
        @klass.stubs(:csv_input_columns).returns(%w[foo])
        csv_enum = [%w[foo], %w[test]]
        assert_nil @klass.csv_input_columns_check(csv_enum)
      end
    end

    describe 'csv_input_columns is a hash' do
      it 'successfully checks the amount of columns' do
        csv_enum = [['Col 1', 'Col 3'], %w[test test2]]
        assert_nil @klass.csv_input_columns_check(csv_enum)
      end
    end

    it 'raises a DuplicatedColumns error on duplicated columns' do
      csv_enum = [%w[foo foo Col\ 1 Col\ 3], %w[test test2 tes test]]
      err = assert_raises(WorkerTools::Errors::DuplicatedColumns) { @klass.csv_input_columns_check(csv_enum) }
      assert_includes err.message, 'The file contains duplicated columns:'
    end

    describe 'raises on missing columns' do
      it 'should raise on missing columns' do
        @klass.stubs(:csv_input_columns).returns(
          col_1: 'Col 1',
          col_2: /Col 2/i,
          col_3: ->(name) { name.downcase == 'col 3' }
        )
        csv_enum = [['Col X', 'Col 2', 'Col 3'], %w[test test test]]
        err = assert_raises(WorkerTools::Errors::MissingColumns) { @klass.csv_input_columns_check(csv_enum) }
        assert_includes err.message, 'Some columns are missing:'

        csv_enum = [['Col 1', 'Col X', 'Col 3'], %w[test test test]]
        err = assert_raises(WorkerTools::Errors::MissingColumns) { @klass.csv_input_columns_check(csv_enum) }
        assert_includes err.message, 'Some columns are missing:'

        csv_enum = [['Col 1', 'Col 2', 'Col X'], %w[test test test]]
        err = assert_raises(WorkerTools::Errors::MissingColumns) { @klass.csv_input_columns_check(csv_enum) }
        assert_includes err.message, 'Some columns are missing:'

        csv_enum = [['Col 1', 'Col 2', 'Col 3'], %w[test test test]]
        assert_nil @klass.csv_input_columns_check(csv_enum)
      end
    end
  end

  describe '#csv_input_mapping_order_for_hash' do
    it 'should find the matching positions' do
      @klass.stubs(:csv_input_columns).returns(
        col_1: 'Col 1',
        col_2: /Col 2/i,
        col_3: ->(name) { name.downcase == 'col 3' }
      )
      header_names = ['COL 3', 'CoL 2', 'Col 1']
      assert_equal({ col_1: 2, col_2: 1, col_3: 0 }, @klass.csv_input_mapping_order_for_hash(header_names))
    end
  end

  describe '#csv_input_foreach' do
    it 'should run by default' do
      @klass.stubs(:csv_input_file_path).returns(test_gem_path + '/test/fixtures/sample.csv')
      content = []
      @klass.csv_input_foreach.each { |row| content << row }
      assert_equal ({ 'col_1' => 'cell_1.1', 'col_3' => 'cell_1.3' }), content.first
      assert_equal ({ 'col_1' => 'cell_2.1', 'col_3' => 'cell_2.3' }), content.second
    end

    it 'should run where all columns are read for hash' do
      @klass.stubs(:csv_input_file_path).returns(test_gem_path + '/test/fixtures/sample.csv')
      @klass.stubs(:csv_input_include_other_columns).returns(true)
      content = []
      @klass.csv_input_foreach.each { |row| content << row }
      assert_equal ({ 'col_1' => 'cell_1.1', 'col 2' => 'cell_1.2', 'col_3' => 'cell_1.3' }), content.first
      assert_equal ({ 'col_1' => 'cell_2.1', 'col 2' => 'cell_2.2', 'col_3' => 'cell_2.3' }), content.second
    end

    it 'should work with files without headers' do
      klass = FooWithoutHeaders.new
      klass.stubs(:csv_input_file_path).returns(test_gem_path + '/test/fixtures/sample_without_headers.csv')

      content = klass.csv_input_foreach.to_a
      assert_equal ({ 'col_1' => 'cell_1.1', 'col_2' => 'cell_1.2', 'col_3' => 'cell_1.3' }), content.first
      assert_equal ({ 'col_1' => 'cell_2.1', 'col_2' => 'cell_2.2', 'col_3' => 'cell_2.3' }), content.second
    end

    it 'should raise EmptyFile error when file is empty' do
      @klass.stubs(:csv_input_file_path).returns(test_gem_path + '/test/fixtures/empty_file.csv')
      err = assert_raises(WorkerTools::Errors::EmptyFile) { @klass.csv_input_foreach }
      assert_equal 'The file is empty', err.message
    end

    it 'should raise EmptyFile error when file has only headers' do
      @klass.stubs(:csv_input_file_path).returns(test_gem_path + '/test/fixtures/only_headers.csv')
      err = assert_raises(WorkerTools::Errors::EmptyFile) { @klass.csv_input_foreach }
      assert_equal 'The file is empty', err.message
    end
  end
end
