require 'test_helper'

describe WorkerTools::XlsxOutput do
  class Foo
    include WorkerTools::XlsxOutput
  end

  it 'needs xlsx_output_target to be defined' do
    klass = Foo.new
    err = assert_raises(RuntimeError) { klass.xlsx_output_target }
    assert_includes err.message, 'xlsx_output_target has to be defined in'
  end

  it 'needs xlsx_output_values to be defined' do
    klass = Foo.new
    err = assert_raises(RuntimeError) { klass.xlsx_output_values }
    assert_includes err.message, 'xlsx_output_values has to be defined in'
  end

  it 'needs xlsx_output_column_headers to be defined' do
    klass = Foo.new
    err = assert_raises(RuntimeError) { klass.xlsx_output_column_headers }
    assert_includes err.message, 'xlsx_output_column_headers has to be defined in'
  end

  describe 'xlsx file output with array' do
    class FooCorrectArray
      include WorkerTools::XlsxOutput

      def xlsx_output_column_headers
        %w[foo1 goo2]
      end

      def xlsx_output_values
        [
          %w[test1 testA],
          %w[test2 testB]
        ]
      end

      def xlsx_output_target
        './tmp/foo_correct.xlsx'
      end

      def xlsx_output_column_format
        {
          a: { width: 20.0, text_wrap: true },
          b: { width: 10.0 }
        }
      end
    end

    def setup
      @klass = FooCorrectArray.new
    end

    it 'no method definition raises and methods are well defined' do
      assert @klass.xlsx_output_target
      assert @klass.xlsx_output_values
      assert @klass.xlsx_output_column_headers
    end

    it 'successful writing of xlsx file' do
      assert @klass.xlsx_output_column_format
      @klass.expects(:xlsx_style_columns).returns(true)

      @klass.xlsx_write_output_target
      assert File.exist?(@klass.xlsx_output_target)
      xlsx = Roo::Excelx.new('./tmp/foo_correct.xlsx')

      sheet = xlsx.sheet(0)
      assert sheet
      assert_equal sheet.row(1), %w[foo1 goo2]
      assert_equal sheet.row(2), %w[test1 testA]
      assert_equal sheet.row(3), %w[test2 testB]
    end
  end

  describe 'xlsx file output with hash' do
    class FooCorrectHash
      include WorkerTools::XlsxOutput

      def xlsx_output_column_headers
        { a: 'foo1', b: 'goo2' }
      end

      def xlsx_output_values
        [
          { a: 'test1', b: 'testA' },
          { b: 'testB', a: 'test2' }
        ]
      end

      def xlsx_output_column_format
        {
          a: { width: 20.0 },
          b: { width: 10.0, text_wrap: true }
        }
      end

      def xlsx_output_target
        './tmp/foo_correct.xlsx'
      end
    end

    def setup
      @klass = FooCorrectHash.new
    end

    it 'no method definition raises and methods are well defined' do
      assert @klass.xlsx_output_target
      assert @klass.xlsx_output_values
      assert @klass.xlsx_output_column_headers
    end

    it 'successful writing of xlsx file' do
      assert @klass.xlsx_output_column_format
      @klass.expects(:xlsx_style_columns).returns(true)

      @klass.xlsx_write_output_target
      assert File.exist?(@klass.xlsx_output_target)
      xlsx = Roo::Excelx.new('./tmp/foo_correct.xlsx')

      sheet = xlsx.sheet(0)
      assert sheet
      assert_equal sheet.row(1), %w[foo1 goo2]
      assert_equal sheet.row(2), %w[test1 testA]
    end
  end
end
