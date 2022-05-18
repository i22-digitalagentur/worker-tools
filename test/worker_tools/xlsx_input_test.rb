require 'test_helper'

describe WorkerTools::XlsxInput do
  class FooWithoutXlsxInputColumns
    include WorkerTools::XlsxInput
  end

  class Foo
    include WorkerTools::XlsxInput

    def xlsx_input_columns
      {
        col_1: 'Col 1',
        col_3: 'Col 3'
      }
    end
  end

  def setup
    @klass = Foo.new
  end

  it 'needs xlsx_input_columns to be defined' do
    err = assert_raises(StandardError) { FooWithoutXlsxInputColumns.new.xlsx_input_columns }
    assert_includes err.message, 'xlsx_input_columns has to be defined in'
  end

  describe '#xlsx_input_header_normalized' do
    it 'should remove leading and trailing spaces' do
      assert_equal 'hallo', @klass.xlsx_input_header_normalized("  \thallo \n\t   \t")
    end

    it 'should return string' do
      assert_equal '', @klass.xlsx_input_header_normalized(nil)
      assert_equal '6', @klass.xlsx_input_header_normalized(6)
      assert_equal '6.66', @klass.xlsx_input_header_normalized(6.66)
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

  describe '#xlsx_input_columns_check' do
    describe 'xlsx_input_columns is an array' do
      it 'raise an exception if column amount differs' do
        @klass.stubs(:xlsx_input_columns).returns(%w[foo])
        xlsx_enum = [%w[foo foo2], %w[test test2]]
        err = assert_raises(WorkerTools::Errors::WrongNumberOfColumns) { @klass.xlsx_input_columns_check(xlsx_enum) }
        assert_includes err.message, 'The number of columns'
      end

      it 'successfully checks the amount of columns' do
        @klass.stubs(:xlsx_input_columns).returns(%w[foo])
        xlsx_enum = [%w[foo], %w[test]]
        assert_nil @klass.xlsx_input_columns_check(xlsx_enum)
      end
    end

    describe 'xlsx_input_columns is a hash' do
      it 'successfully checks the amount of columns' do
        xlsx_enum = [['Col 1', 'Col 3'], %w[test test2]]
        assert_nil @klass.xlsx_input_columns_check(xlsx_enum)
      end
    end

    describe 'raises on duplication' do
      it 'should raise on duplicated columns' do
        xlsx_enum = [%w[foo foo Col\ 1 Col\ 3], %w[test test2 tes test]]
        err = assert_raises(WorkerTools::Errors::DuplicatedColumns) { @klass.xlsx_input_columns_check(xlsx_enum) }
        assert_includes err.message, 'The file contains duplicated columns:'
      end
    end

    describe 'raises on missing columns' do
      it 'should raise on missing columns' do
        @klass.stubs(:xlsx_input_columns).returns(
          col_1: 'Col 1',
          col_2: /Col 2/i,
          col_3: ->(name) { name.downcase == 'col 3' }
        )
        xlsx_enum = [['Col X', 'Col 2', 'Col 3'], %w[test test test]]
        err = assert_raises(WorkerTools::Errors::MissingColumns) { @klass.xlsx_input_columns_check(xlsx_enum) }
        assert_includes err.message, 'Some columns are missing:'

        xlsx_enum = [['Col 1', 'Col X', 'Col 3'], %w[test test test]]
        err = assert_raises(WorkerTools::Errors::MissingColumns) { @klass.xlsx_input_columns_check(xlsx_enum) }
        assert_includes err.message, 'Some columns are missing:'

        xlsx_enum = [['Col 1', 'Col 2', 'Col X'], %w[test test test]]
        err = assert_raises(WorkerTools::Errors::MissingColumns) { @klass.xlsx_input_columns_check(xlsx_enum) }
        assert_includes err.message, 'Some columns are missing:'

        xlsx_enum = [['Col 1', 'Col 2', 'Col 3'], %w[test test test]]
        assert_nil @klass.xlsx_input_columns_check(xlsx_enum)
      end
    end
  end

  describe '#xlsx_input_mapping_order_for_hash' do
    it 'should find the matching positions' do
      @klass.stubs(:xlsx_input_columns).returns(
        col_1: 'Col 1',
        col_2: /Col 2/i,
        col_3: ->(name) { name.downcase == 'col 3' }
      )
      header_names = ['COL 3', 'CoL 2', 'Col 1']
      assert_equal({ col_1: 2, col_2: 1, col_3: 0 }, @klass.xlsx_input_mapping_order_for_hash(header_names))
    end
  end

  describe '#xlsx_input_foreach' do
    it 'should run by default' do
      @klass.stubs(:xlsx_input_file_path).returns(test_gem_path + '/test/fixtures/sample.xlsx')
      content = []
      @klass.xlsx_input_foreach.each { |row| content << row }
      assert_equal ({ 'col_1' => 'cell_1.1', 'col_3' => 'cell_1.3' }), content.first
      assert_equal ({ 'col_1' => 'cell_2.1', 'col_3' => 'cell_2.3' }), content.second
    end

    it 'should run where all columns are read for hash' do
      @klass.stubs(:xlsx_input_file_path).returns(test_gem_path + '/test/fixtures/sample.xlsx')
      @klass.stubs(:xlsx_input_include_other_columns).returns(true)
      content = []
      @klass.xlsx_input_foreach.each { |row| content << row }
      assert_equal ({ 'col_1' => 'cell_1.1', 'col 2' => 'cell_1.2', 'col_3' => 'cell_1.3' }), content.first
      assert_equal ({ 'col_1' => 'cell_2.1', 'col 2' => 'cell_2.2', 'col_3' => 'cell_2.3' }), content.second
    end
  end
end
