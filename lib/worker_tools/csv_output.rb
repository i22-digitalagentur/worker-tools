require 'csv'

module WorkerTools
  module CsvOutput
    def csv_output_entries
      raise "csv_output_entries has to be defined in #{self}"
    end

    def csv_output_column_headers
      # These columns are used to set the headers, also
      # to set the row values depending on your implementation.
      #
      # To ignore them set it to _false_
      #
      # Ex:
      # @csv_output_column_headers ||= {
      #   foo: 'Foo Header',
      #   bar: 'Bar Header'
      # }
      raise "csv_output_column_headers has to be defined in #{self}"
    end

    def csv_output_row_values(entry)
      entry.values_at(*csv_output_column_headers.keys)
    end

    def csv_output_tmp_file
      @csv_output_tmp_file ||= Tempfile.new(['output', '.csv'])
    end

    def csv_output_file_name
      "#{model_kind}.csv"
    end

    def csv_output_col_sep
      ';'
    end

    def csv_output_encoding
      Encoding::UTF_8
    end

    def csv_output_write_mode
      'wb'
    end

    def csv_output_csv_options
      { col_sep: csv_output_col_sep, encoding: csv_output_encoding }
    end

    def csv_output_insert_headers(csv)
      csv << csv_output_column_headers.values if csv_output_column_headers
    end

    def csv_output_add_attachment
      model.add_attachment(csv_output_tmp_file, file_name: csv_output_file_name, content_type: 'text/csv')
    end

    def csv_output_write_file
      CSV.open(csv_output_tmp_file, csv_output_write_mode, **csv_output_csv_options) do |csv|
        csv_output_insert_headers(csv)
        csv_output_entries.each { |entry| csv << csv_output_row_values(entry) }
      end

      csv_output_add_attachment
    end
  end
end
