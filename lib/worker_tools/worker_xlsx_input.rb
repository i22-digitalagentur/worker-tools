module WorkerXlsxInput
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
    name.to_s.strip.downcase
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
    raise "The number of columns (#{actual_columns_length}) is not the expected (#{expected_columns_length})"
  end

  def xlsx_input_columns_hash_check(xlsx_rows_enum)
    expected_names = xlsx_input_columns.values
    filtered_actual_names = xlsx_rows_enum.first.map { |n| xlsx_input_header_normalized(n) }
    xlsx_input_columns_hash_check_duplicates(filtered_actual_names)
    xlsx_input_columns_hash_check_missing(filtered_actual_names, expected_names)
  end

  def xlsx_input_columns_hash_check_duplicates(names)
    dups = names.group_by(&:itself).select { |_, v| v.count > 1 }.keys
    raise "The file contains duplicated columns: #{dups}" if dups.present?
  end

  def xlsx_input_columns_hash_check_missing(actual_names, expected_names)
    missing = expected_names.reject do |name|
      actual_names.include?(xlsx_input_header_normalized(name))
    end
    raise "Some columns are missing: #{missing}" unless missing.empty?
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
      h[k] = filtered_column_names.index(xlsx_input_header_normalized(v))
    end
    return mapping unless xlsx_input_include_other_columns

    positions_taken = mapping.values
    filtered_column_names.each_with_index do |header, index|
      mapping[header] = index unless positions_taken.include?(index)
    end
    mapping
  end

  def xlsx_input_foreach
    @xlsx_input_foreach ||= begin
      spreadsheet = Roo::Excelx.new(model.attachment.path.to_s)
      xlsx_rows_enum = spreadsheet.each_row_streaming(sheet: spreadsheet.sheets.first, pad_cells: true)

      xlsx_input_columns_check(xlsx_rows_enum)
      mapping_order = xlsx_input_mapping_order(xlsx_rows_enum.first)
      cleanup_method = method(:xlsx_input_value_cleanup)

      WorkerXlsxInputForeach.new(xlsx_rows_enum, mapping_order, cleanup_method)
    end
  end

  class WorkerXlsxInputForeach
    include Enumerable

    def initialize(rows_enum, mapping_order, cleanup_method)
      @rows_enum = rows_enum
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
      @mapping_order.each_with_object(HashWithIndifferentAccess.new) do |(k, v), h|
        h[k] = @cleanup_method.call(values[v].try(:value))
      end
    end
  end
end
