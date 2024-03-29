require 'rubyXL'
module WorkerTools
  module XlsxOutput
    def xlsx_output_entries
      raise "xlsx_output_entries has to be defined in #{self}"
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

    def xlsx_output_content
      {
        sheet1: {
          label: 'Sheet 1',
          headers: xlsx_output_column_headers,
          rows: xlsx_output_entries.lazy.map { |entry| xlsx_output_row_values(entry) },
          column_style: xlsx_output_column_format
        }
      }
    end

    def xlsx_output_row_values(entry)
      entry.values_at(*xlsx_output_column_headers.keys)
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
      {}
    end

    def xlsx_output_insert_headers(spreadsheet, headers)
      return unless headers

      iterator =
        if headers.is_a? Hash
          headers.values
        else
          headers
        end
      iterator.each_with_index do |header, index|
        spreadsheet.add_cell(0, index, header.to_s)
      end
    end

    def xlsx_output_insert_rows(spreadsheet, rows, headers)
      rows.each_with_index do |row, row_index|
        xlsx_output_iterators(row, headers).each_with_index do |value, col_index|
          spreadsheet.add_cell(row_index + 1, col_index, value.to_s)
        end
      end
    end

    def xlsx_output_iterators(iterable, compare_hash = nil)
      if iterable.is_a? Hash
        raise 'parameter compare_hash should be a hash, too.' if compare_hash.nil? || !compare_hash.is_a?(Hash)

        iterable.values_at(*compare_hash.keys)
      else
        iterable
      end
    end

    def xlsx_output_style_columns(spreadsheet, styles, headers)
      return false unless headers

      xlsx_output_iterators(styles, headers).each_with_index do |format, index|
        next unless format

        spreadsheet.change_column_width(index, format[:width])
        spreadsheet.change_text_wrap(index, format[:text_wrap])
      end
      true
    end

    def xlsx_output_tmp_file
      @xlsx_output_tmp_file ||= Tempfile.new(['output', '.xlsx'])
    end

    def xlsx_output_file_name
      "#{model_kind}.xlsx"
    end

    def xlsx_output_add_attachment
      model.add_attachment(
        xlsx_output_tmp_file,
        file_name: xlsx_output_file_name,
        content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      )
    end

    def xlsx_output_write_sheet(workbook, sheet_content, index)
      sheet = workbook.worksheets[index]
      sheet = workbook.add_worksheet(sheet_content[:label]) if sheet.nil?

      sheet.sheet_name = sheet_content[:label]
      xlsx_output_style_columns(sheet, sheet_content[:column_style], sheet_content[:headers])
      xlsx_output_insert_headers(sheet, sheet_content[:headers])
      xlsx_output_insert_rows(sheet, sheet_content[:rows], sheet_content[:headers])
    end

    def xlsx_output_write_file
      book = RubyXL::Workbook.new
      xlsx_output_content.each_with_index do |(_, object), index|
        xlsx_output_write_sheet(book, object, index)
      end

      book.write xlsx_output_tmp_file

      xlsx_output_add_attachment
    end
  end
end
