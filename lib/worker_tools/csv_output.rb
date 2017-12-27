require 'csv'

module WorkerTools
  module CsvOutput
    # if defined, this file will be written to this destination (regardless
    # of whether the model saves the file as well)
    def csv_output_target
      # Ex: Rails.root.join('shared', 'foo', 'bar.csv')
      false
    end

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

    # rubocop:disable Lint/UnusedMethodArgument
    def csv_output_row_values(entry)
      # Ex:
      # {
      #   foo: entry.foo,
      #   bar: entry.bar
      # }.values_at(*csv_output_column_headers.keys)
      raise "csv_output_row_values has to be defined in #{self}"
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def cvs_output_target_folder
      File.dirname(csv_output_target)
    end

    def csv_output_target_file_name
      File.basename(csv_output_target)
    end

    def csv_ouput_ensure_target_folder
      FileUtils.mkdir_p(cvs_output_target_folder) unless File.directory?(cvs_output_target_folder)
    end

    def csv_output_tmp_file
      @csv_output_tmp_file ||= Tempfile.new(['output', '.csv'])
    end

    def csv_output_col_sep
      ';'
    end

    def csv_output_encoding
      Encoding::UTF_8
    end

    def csv_output_insert_headers(csv)
      csv << csv_output_column_headers.values if csv_output_column_headers
    end

    def csv_output_write_file
      CSV.open(csv_output_tmp_file, 'wb', col_sep: csv_output_col_sep, encoding: csv_output_encoding) do |csv|
        csv_output_insert_headers(csv)
        csv_output_entries.each { |entry| csv << csv_output_row_values(entry) }
      end
      csv_output_write_target if csv_output_target
    end

    def csv_output_write_target
      csv_ouput_ensure_target_folder
      FileUtils.cp(csv_output_tmp_file.path, csv_output_target)
    end
  end
end
