require 'test_helper'

describe WorkerTools::XlsxOutput do
  class FooXlsxOutput
    include WorkerTools::Basics
    include WorkerTools::XlsxOutput

    wrappers :basics

    def model_class
      Import
    end

    def model_kind
      'foo_test'
    end
  end

  it 'raises an error if xlsx_output_entries are not defined' do
    klass = FooXlsxOutput.new
    err = assert_raises(StandardError) { klass.xlsx_output_entries }
    assert_includes err.message, 'xlsx_output_entries has to be defined in'
  end

  it 'raises an error if xlsx_output_column_headers are not defined' do
    klass = FooXlsxOutput.new
    err = assert_raises(StandardError) { klass.xlsx_output_column_headers }
    assert_includes err.message, 'xlsx_output_column_headers has to be defined in'
  end

  describe 'xlsx file output with hash' do
    class FooCorrectHash < FooXlsxOutput
      def xlsx_output_column_headers
        { a: 'foo1', b: 'goo2' }
      end

      def xlsx_output_entries
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
    end

    def setup
      @klass = FooCorrectHash.new
    end

    it 'no method definition raises and methods are well defined' do
      assert @klass.xlsx_output_row_values(@klass.xlsx_output_entries.first)
      assert @klass.xlsx_output_column_headers
    end

    it 'successful writing of xlsx file' do
      assert @klass.xlsx_output_column_format
      @klass.expects(:xlsx_output_style_columns).returns(true)

      @klass.xlsx_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      xlsx = Roo::Excelx.new(attachment.file.path)

      sheet = xlsx.sheet(0)
      assert sheet
      assert_equal xlsx.sheets, ['Sheet 1']
      assert_equal sheet.row(1), %w[foo1 goo2]
      assert_equal sheet.row(2), %w[test1 testA]
    end
  end

  describe 'xlsx file output with number_format' do
    class FooNumberFormat < FooXlsxOutput
      def xlsx_output_column_headers
        {
          number: 'Number',
          number_auto: 'Number Auto',
          number_formatted: 'Number Formatted',
          date: 'Date',
          date_auto: 'Date Auto',
          date_formatted: 'Date Formatted'
        }
      end

      def xlsx_output_number_format
        {
          number_auto: :auto,
          number_formatted: '0.00',
          date_auto: :auto,
          date_formatted: 'yyyy'
        }
      end

      def xlsx_output_entries
        date = DateTime.parse('2020-10-15T14:00:00Z').utc

        [
          {
            number: 1.2345,
            number_auto: 1.2345,
            number_formatted: 1.2345,
            date: date,
            date_auto: date,
            date_formatted: date
          }
        ]
      end
    end

    def setup
      @klass = FooNumberFormat.new
    end

    it 'formats the columns' do
      @klass.xlsx_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      xlsx = Roo::Excelx.new(attachment.file.path)
      sheet = xlsx.sheet(0)
      assert sheet
      # formatted value or sheet.row does not show us what excel ends up displaying
      # but it help us to verify that the format changes.
      # This is what my excel shows:
      # 1.2345  1,2345  1,23  2020-10-15 14:00:00 UTC  44119,58333  2020
      assert_equal sheet.formatted_value(2, 1), '1.2345'
      assert_equal sheet.formatted_value(2, 2), '1'
      assert_equal sheet.formatted_value(2, 3), '1.23'
      assert_equal sheet.formatted_value(2, 4), '2020-10-15 14:00:00 UTC'
      assert_equal sheet.formatted_value(2, 5), '44120'
      assert_equal sheet.formatted_value(2, 6), '2020-10-15 00:00:00'
    end
  end

  describe 'xlsx file output with array - multi sheet' do
    class FooCorrectArrayMultiSheet < FooXlsxOutput
      def xlsx_output_content
        {
          sheet_1: {
            label: 'Test 1',
            headers: xlsx_output_column_headers,
            rows: xlsx_output_row_values,
            column_style: xlsx_output_column_format
          },
          sheet_2: {
            label: 'Test 2',
            headers: xlsx_output_column_headers,
            rows: xlsx_output_row_values,
            column_style: xlsx_output_column_format
          }
        }
      end

      def xlsx_output_column_headers
        %w[foo1 goo2]
      end

      def xlsx_output_row_values
        [
          %w[test1 testA],
          %w[test2 testB]
        ]
      end

      def xlsx_output_column_format
        {
          a: { width: 20.0, text_wrap: true },
          b: { width: 10.0 }
        }
      end
    end

    def setup
      @klass = FooCorrectArrayMultiSheet.new
    end

    it 'successful writing of xlsx file' do
      assert @klass.xlsx_output_column_format
      @klass.expects(:xlsx_output_style_columns).at_least_once

      @klass.xlsx_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      assert_instance_of Tempfile, attachment.file
      assert_equal 'foo_test.xlsx', attachment.file_name
      assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', attachment.content_type
      xlsx = Roo::Excelx.new(attachment.file.path)

      assert xlsx.sheet(0)
      assert xlsx.sheet(1)
      assert_equal xlsx.sheets, ['Test 1', 'Test 2']
      assert_equal xlsx.sheet(0).row(1), %w[foo1 goo2]
      assert_equal xlsx.sheet(0).row(2), %w[test1 testA]
      assert_equal xlsx.sheet(0).row(3), %w[test2 testB]
      assert_equal xlsx.sheet(1).row(1), %w[foo1 goo2]
      assert_equal xlsx.sheet(1).row(2), %w[test1 testA]
      assert_equal xlsx.sheet(1).row(3), %w[test2 testB]
    end
  end

  describe 'xlsx file output with hash - multi sheet' do
    class FooCorrectHashMultiSheet < FooXlsxOutput
      def xlsx_output_column_headers
        { a: 'foo1', b: 'goo2' }
      end

      def xlsx_output_row_values
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

      def xlsx_output_content
        {
          sheet_1: {
            label: 'Test 1',
            headers: xlsx_output_column_headers,
            rows: xlsx_output_row_values,
            column_style: xlsx_output_column_format
          },
          sheet_2: {
            label: 'Test 2',
            headers: xlsx_output_column_headers,
            rows: xlsx_output_row_values,
            column_style: xlsx_output_column_format
          }
        }
      end
    end

    def setup
      @klass = FooCorrectHashMultiSheet.new
    end

    it 'successful writing of xlsx file' do
      assert @klass.xlsx_output_column_format
      @klass.expects(:xlsx_output_style_columns).at_least_once

      @klass.xlsx_output_write_file
      attachment = @klass.model.attachments.first
      assert attachment
      xlsx = Roo::Excelx.new(attachment.file.path)

      assert xlsx.sheet(0)
      assert xlsx.sheet(1)
      assert_equal xlsx.sheets, ['Test 1', 'Test 2']
      assert_equal xlsx.sheet(0).row(1), %w[foo1 goo2]
      assert_equal xlsx.sheet(0).row(2), %w[test1 testA]
      assert_equal xlsx.sheet(0).row(3), %w[test2 testB]
      assert_equal xlsx.sheet(1).row(1), %w[foo1 goo2]
      assert_equal xlsx.sheet(1).row(2), %w[test1 testA]
      assert_equal xlsx.sheet(1).row(3), %w[test2 testB]
    end
  end
end
