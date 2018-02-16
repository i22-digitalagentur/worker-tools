require 'csv'

module WorkerTools
  module CsvInput
    # If an array is provided, the names will be used as the row keys, the row
    # values will be assign according to the columns order.
    #
    # Ex: %w(tenant segment area)
    # row => {
    #   tenant: _value_at_first_column_,
    #   segment: _value_at_second_column_,
    #   area: _value_at_third_column_
    # }
    #
    # If a hash if provided, the keys will turn into the row keys, the values
    # will be used to find the corresponding columns (the order in the csv won't
    # affect the import)
    #
    # Ex: { tenant: 'Mandant', segment: 'Segment', area: 'Bereich')
    # row => {
    #   tenant: _value_at_column_Mandant,
    #   segment: _value_at_column_Segment,
    #   area: _value_at_column_Bereich
    # }
    #
    # The name of the column is filtered using the csv_input_header_normalized
    # method, which takes care of extra spaces and looks for a case insentive
    # match (so 'Bereich' matches ' Bereich', 'bereich', etc.). You can override
    # that method as well.
    def csv_input_columns
      raise "csv_input_columns has to be defined in #{self}"
    end

    def csv_input_header_normalized(name)
      name = name.to_s.strip
      name = name.downcase if csv_input_header_normalize?
      name
    end

    # Allows for some basic cleanup of the values, such as applying strip to
    # the strings.
    def cvs_input_value_cleanup(value)
      value.is_a?(String) ? value.strip : value
    end

    def csv_input_columns_check(csv_rows_enum)
      # override and return true if you do not want this check to be performed
      return csv_input_columns_array_check(csv_rows_enum) if csv_input_columns.is_a?(Array)
      csv_input_columns_hash_check(csv_rows_enum)
    end

    def csv_input_columns_array_check(csv_rows_enum)
      expected_columns_length = csv_input_columns.length
      actual_columns_length = csv_rows_enum.first.length
      return if expected_columns_length == actual_columns_length
      raise "The number of columns (#{actual_columns_length}) is not the expected (#{expected_columns_length})"
    end

    def csv_input_columns_hash_check(csv_rows_enum)
      expected_names = csv_input_columns.values
      filtered_actual_names = csv_rows_enum.first.map { |n| csv_input_header_normalized(n) }
      csv_input_columns_hash_check_duplicates(filtered_actual_names)
      csv_input_columns_hash_check_missing(filtered_actual_names, expected_names)
    end

    def csv_input_columns_hash_check_duplicates(names)
      dups = names.group_by(&:itself).select { |_, v| v.count > 1 }.keys
      raise "The file contains duplicated columns: #{dups}" if dups.present?
    end

    def csv_input_columns_hash_check_missing(actual_names, expected_names)
      missing = expected_names.reject do |name|
        actual_names.include?(csv_input_header_normalized(name))
      end
      raise "Some columns are missing: #{missing}" unless missing.empty?
    end

    def csv_input_csv_options
      # Ex: { col_sep: ';', encoding: Encoding::ISO_8859_1 }
      { col_sep: ';' }
    end

    def csv_input_include_other_columns
      false
    end

    def csv_input_header_normalize?
      true
    end

    # Compares the first row (header names) with the csv_input_columns hash to find
    # the corresponding positions.
    #
    # Ex: csv_input_columns: {tenant: 'Mandant', area: 'Bereich'}
    #     headers: ['Bereich', 'Mandant']
    #     =>  { tenant: 1, area: 0}
    # def csv_input_mapping_order(header_names)
    #   return unless csv_input_columns.is_a?(Hash)
    #   filtered_column_names = header_names.map { |n| csv_input_header_normalized(n) }
    #   csv_input_columns.each_with_object({}) do |(k, v), h|
    #     h[k] = filtered_column_names.index(csv_input_header_normalized(v))
    #   end
    # end

    def csv_input_mapping_order(header_names)
      return csv_input_columns.map.with_index { |n, i| [n, i] }.to_h if csv_input_columns.is_a?(Array)
      csv_input_mapping_order_for_hash(header_names)
    end

    def csv_input_mapping_order_for_hash(header_names)
      filtered_column_names = header_names.map { |n| csv_input_header_normalized(n) }
      mapping = csv_input_columns.each_with_object({}) do |(k, v), h|
        h[k] = filtered_column_names.index(csv_input_header_normalized(v))
      end
      return mapping unless csv_input_include_other_columns

      positions_taken = mapping.values
      filtered_column_names.each_with_index do |header, index|
        mapping[header.to_sym] = index unless positions_taken.include?(index)
      end
      mapping
    end

    def csv_input_file_path
      model.attachment.path.to_s
    end

    def csv_input_foreach
      @csv_input_rows ||= begin
        csv_rows_enum = CSV.foreach(csv_input_file_path, csv_input_csv_options)
        csv_input_columns_check(csv_rows_enum)
        mapping_order = csv_input_mapping_order(csv_rows_enum.first)
        cleanup_method = method(:cvs_input_value_cleanup)

        WorkerCsvInputForeach.new(csv_rows_enum, csv_input_columns, mapping_order, cleanup_method)
      end
    end

    class WorkerCsvInputForeach
      include Enumerable

      def initialize(rows_enum, input_columns, mapping_order, cleanup_method)
        @rows_enum = rows_enum
        @input_columns = input_columns
        @mapping_order = mapping_order
        @cleanup_method = cleanup_method
      end

      def each
        @rows_enum.with_index.each do |values, index|
          next if index.zero? # headers
          yield values_to_row(values)
        end
      end

      def values_to_row(values)
        return values_to_row_according_to_mapping(values) if @mapping_order
        values_to_row_according_to_position(values)
      end

      def values_to_row_according_to_mapping(values)
        @mapping_order.each_with_object({}) { |(k, v), h| h[k] = @cleanup_method.call(values[v]) }
      end

      def values_to_row_according_to_position(values)
        @input_columns.map.with_index { |c, i| [c, @cleanup_method.call(values[i])] }.to_h
      end
    end
  end
end
