require 'rubyXL'
module WorkerTools
  module XlsxOutput
    # if defined, this file will be written to this destination (regardless
    # of whether the model saves the file as well)
    def xlsx_output_target
      # Ex: Rails.root.join('shared', 'foo', 'bar.xlsx')
      raise "xlsx_output_target has to be defined in #{self}"
    end

    def xlsx_output_content
      {
        sheet1: {
          value: 'Sheet 1',
          headers: xlsx_output_column_headers,
          rows: xlsx_output_values
        }
      }
    end

    def xlsx_output_values
      raise "xlsx_output_values has to be defined in #{self}"
    end

    def xlsx_output_column_headers
      # These columns are used to set the headers, also
      # to set the row values depending on your implementation.
      #
      # To ignore them set it to _false_
      #
      # Ex:
      # @xlsx_output_column_headers ||= {
      #   foo: 'Foo Header',
      #   bar: 'Bar Header'
      # }
      raise "xlsx_output_column_headers has to be defined in #{self}"
    end

    def xlsx_output_column_format
      # These columns are used to set the headers, also
      # to set the row values depending on your implementation.
      #
      # To ignore them set it to _false_
      #
      # Ex:
      # @xlsx_output_column_format ||= {
      #   foo: { width: 10, text_wrap: true },
      #   bar: { width: 20, text_wrap: false }
      # }
      false
    end

    def xlsx_output_target_folder
      @xlsx_output_target_folder ||= File.dirname(xlsx_output_target)
    end

    def xlsx_ensure_output_target_folder
      FileUtils.mkdir_p(xlsx_output_target_folder) unless File.directory?(xlsx_output_target_folder)
    end

    def xlsx_insert_headers(spreadsheet)
      return unless xlsx_output_column_headers
      iterator =
        if xlsx_output_column_headers.is_a? Hash
          xlsx_output_column_headers.values
        else
          xlsx_output_column_headers
        end
      iterator.each_with_index do |header, index|
        spreadsheet.add_cell(0, index, header.to_s)
      end
    end

    def xlsx_insert_rows(spreadsheet)
      xlsx_output_values.each_with_index do |row, row_index|
        xlsx_iterators(row, xlsx_output_column_headers).each_with_index do |value, col_index|
          spreadsheet.add_cell(row_index + 1, col_index, value.to_s)
        end
      end
    end

    def xlsx_iterators(iterable, compare_hash = nil)
      if iterable.is_a? Hash
        raise 'parameter compare_hash shourakeld be a hash, too.' if compare_hash.nil? || !compare_hash.is_a?(Hash)
        iterable.values_at(*compare_hash.keys)
      else
        iterable
      end
    end

    def xlsx_style_columns(spreadsheet)
      return false unless xlsx_output_column_format

      xlsx_iterators(xlsx_output_column_format, xlsx_output_column_headers).each_with_index do |format, index|
        spreadsheet.change_column_width(index, format[:width])
        spreadsheet.change_text_wrap(index, format[:text_wrap])
      end
      true
    end

    def xlsx_write_output_target
      xlsx_ensure_output_target_folder

      book = RubyXL::Workbook.new
      sheet1 = book.worksheets[0]

      xlsx_style_columns(sheet1)
      xlsx_insert_headers(sheet1)
      xlsx_insert_rows(sheet1)

      book.write xlsx_output_target
    end
  end
end
