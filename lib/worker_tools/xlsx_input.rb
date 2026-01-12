require 'roo'

module WorkerTools
  module XlsxInput
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
    # will be used to find the corresponding columns (the order in the spreadsheet
    # won't affect the import)
    #
    # Ex: { tenant: 'Mandant', segment: 'Segment', area: 'Bereich')
    # row => {
    #   tenant: _value_at_column_Mandant,
    #   segment: _value_at_column_Segment,
    #   area: _value_at_column_Bereich
    # }
    #
    # The name of the column is filtered using the xlsx_input_header_normalized
    # method, which takes care of extra spaces and looks for a case insentive
    # match (so 'Bereich' matches ' Bereich', 'bereich', etc.). You can override
    # that method as well.
    #
    # Besides matching the columns using strings, it is possible to use a regular
    # expression or a proc:
    # {
    #   tenant: 'Mandant',
    #   segment: /Segment/i,
    #   area: ->(name) { name.downcase == 'area' }
    # }
    def xlsx_input_columns
      raise "xlsx_input_columns has to be defined in #{self}"
    end

    # If true, the rows will append those columns that don't belong to the
    # xlsx_input_columns list. Useful when the spreadsheet contains some fixed
    # columns and a number of variable ones.
    def xlsx_input_include_other_columns
      false
    end

    def xlsx_input_header_normalized(name)
      # some elements return obj.to_s => nil
      # for example [#<Roo::Excelx::Cell::Empty:0x0000000af8d4c8 ... @value=nil>]
      name&.to_s&.strip&.downcase || ''
    end

    # Allows for some basic cleanup of the values, such as applying strip to
    # the strings.
    def xlsx_input_value_cleanup(value)
      value.is_a?(String) ? value.strip : value
    end

    def xlsx_input_columns_check(xlsx_rows_enum)
      # override and return true if you do not want this check to be performed
      return xlsx_input_columns_array_check(xlsx_rows_enum) if xlsx_input_columns.is_a?(Array)

      xlsx_input_columns_hash_check(xlsx_rows_enum)
    end

    def xlsx_input_columns_array_check(xlsx_rows_enum)
      expected_columns_length = xlsx_input_columns.length
      actual_columns_length = xlsx_rows_enum.first.length
      return if expected_columns_length == actual_columns_length

      msg = "The number of columns (#{actual_columns_length}) is not the expected (#{expected_columns_length})"
      raise Errors::WrongNumberOfColumns, msg
    end

    def xlsx_input_columns_hash_check(xlsx_rows_enum)
      expected_names = xlsx_input_columns.values
      filtered_actual_names = xlsx_rows_enum.first.map { |n| xlsx_input_header_normalized(n) }
      xlsx_input_columns_hash_check_duplicates(filtered_actual_names)
      xlsx_input_columns_hash_check_missing(filtered_actual_names, expected_names)
    end

    def xlsx_input_columns_hash_check_duplicates(names)
      dups = names.group_by(&:itself).select { |_, v| v.count > 1 }.keys
      return unless dups.present?

      raise Errors::DuplicatedColumns, "The file contains duplicated columns: #{dups}"
    end

    def xlsx_input_columns_hash_check_missing(actual_names, expected_names)
      missing = expected_names.reject do |name|
        matchable = name.is_a?(String) ? xlsx_input_header_normalized(name) : name
        actual_names.any? { |n| case n when matchable then true end } # rubocop does not like ===
      end
      raise Errors::MissingColumns, "Some columns are missing: #{missing}" unless missing.empty?
    end

    # Compares the first row (header names) with the xlsx_input_columns hash to find
    # the corresponding positions.
    #
    # Ex: xlsx_input_columns: {tenant: 'Mandant', area: 'Bereich'}
    #     headers: ['Bereich', 'Mandant']
    #     =>  { tenant: 1, area: 0}
    def xlsx_input_mapping_order(header_names)
      return xlsx_input_columns.map.with_index { |n, i| [n, i] }.to_h if xlsx_input_columns.is_a?(Array)

      xlsx_input_mapping_order_for_hash(header_names)
    end

    def xlsx_input_mapping_order_for_hash(header_names)
      filtered_column_names = header_names.map { |n| xlsx_input_header_normalized(n) }
      mapping = xlsx_input_columns.each_with_object({}) do |(k, v), h|
        matchable = v.is_a?(String) ? xlsx_input_header_normalized(v) : v
        h[k] = filtered_column_names.index { |n| case n when matchable then true end }
      end
      return mapping unless xlsx_input_include_other_columns

      xlsx_input_mapping_order_with_other_columns(mapping, filtered_column_names)
    end

    def xlsx_input_mapping_order_with_other_columns(mapping, filtered_column_names)
      positions_taken = mapping.values
      filtered_column_names.each_with_index do |header, index|
        mapping[header] = index unless positions_taken.include?(index)
      end
      mapping
    end

    def xlsx_input_file_path
      model.attachment.path.to_s
    end

    def xlsx_rows_enum
      @xlsx_rows_enum ||= begin
        spreadsheet = Roo::Excelx.new(xlsx_input_file_path)
        spreadsheet.each_row_streaming(sheet: spreadsheet.sheets.first, pad_cells: true)
      end
    end

    def xlsx_input_headers_present
      true
    end

    def xlsx_input_file_presence_check
      raise Errors::EmptyFile, 'The file does not exist' unless File.exist?(xlsx_input_file_path)
      raise Errors::EmptyFile, 'The file is empty' if File.zero?(xlsx_input_file_path)
    end

    def xlsx_input_foreach
      @xlsx_input_foreach ||= begin
        xlsx_input_file_presence_check
        xlsx_input_columns_check(xlsx_rows_enum)

        XlsxInputForeach.new(
          rows_enum: xlsx_rows_enum,
          mapping_order: xlsx_input_mapping_order(xlsx_rows_enum.first),
          cleanup_method: method(:xlsx_input_value_cleanup),
          headers_present: xlsx_input_headers_present
        )
      end
    end

    class XlsxInputForeach
      include Enumerable

      def initialize(rows_enum:, mapping_order:, cleanup_method:, headers_present:)
        @rows_enum = rows_enum
        @mapping_order = mapping_order
        @cleanup_method = cleanup_method
        @headers_present = headers_present
      end

      def each
        return enum_for(:each) unless block_given?

        @rows_enum.with_index.each do |values, index|
          next if index.zero? && @headers_present

          yield values_to_row(values)
        end
      end

      def values_to_row(values)
        @mapping_order.each_with_object(HashWithIndifferentAccess.new) do |(k, v), h|
          h[k] = @cleanup_method.call(values[v].try(:value))
        end
      end
    end
  end
end
