# Changelog

## [1.0.0] - 2022-05-20

Compared to 0.2.1

### Added

- Namespaced errors and non failure logic
- Support for status running and complete_with_warnings
- Benchmark wrapper
- Counters wrapper
- Notes instead of information field
- Filter for slack errors (`slack_error_notifiable`)
- Model attachments convention
- Complete specification of csv open arguments

### Changed

- Instead of writing the final csv or xlsx to a folder, the gem assumes that the model provides an add_attachment method.
- Both csv and xlsx output modules use entry hashes for content (`csv_output_entries`, `xlsx_output_entries`). The mapper methods `csv_output_row_values` and `xlsx_output_row_values` do not need (in most cases) to be defined, there is a default now. See the complete examples in the README.
- Renamed `xlsx_output_values` => `xlsx_output_row_values`
- Renamed `xlsx_insert_headers` => `xlsx_output_insert_headers`
- Renamed `xlsx_insert_rows` => ` xlsx_output_insert_rows`
- Renamed `xlsx_iterators` => `xlsx_output_iterators`
- Renamed `xlsx_style_columns` => `xlsx_output_style_columns`
- Renamed `xlsx_write_sheet` => `xlsx_output_write_sheet`

### Removed

- `add_info` in favor of `add_note`
- `create_model_if_not_available`, a model is always created.
- `format_log_message`, `format_info_message` in favor of `format_message`
- `csv_output_target`
- `cvs_output_target_folder`
- `csv_output_target_file_name`
- `csv_ouput_ensure_target_folder`
- `csv_output_write_target`
- `xlsx_output_target`
- `xlsx_output_target_folder`
- `xlsx_ensure_output_target_folder`
- `xlsx_write_output_target`

[1.0.0]: https://github.com/i22-digitalagentur/worker-tools/compare/0.2.1...1.0.0
