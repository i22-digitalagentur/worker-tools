module WorkerTools
  module Recorder

    def with_wrapper_recorder(&block)
      block.yield
    # this time we do want to catch Exception to attempt to handle some of the
    # critical errors.
    # rubocop:disable Lint/RescueException
    rescue Exception => e
      # rubocop:enable Lint/RescueException
      record_fail(e)
      raise
    end

    def with_wrapper_logger(&block)
      block.yield
    # this time we do want to catch Exception to attempt to handle some of the
    # critical errors.
    # rubocop:disable Lint/RescueException
    rescue Exception => e
      # rubocop:enable Lint/RescueException
      add_log(e, :error)
      raise
    end

    def record_fail(error)
      record(error, :error)
      model.save!(validate: false)
    end

    def add_log(message, level = nil)
      attrs = default_message_attrs(message, level)
      logger.public_send(attrs[:level], format_message(attrs[:message]))
    end

    def add_note(message, level = nil)
      attrs = default_message_attrs(message, level)
      model.notes.push(level: attrs[:level], message: attrs[:message])
    end

    def record(message, level = :info)
      add_log(message, level)
      add_note(message, level)
    end

    def level_from_message_type(message)
      return :error if message.is_a?(Exception)

      :info
    end

    def format_message(message)
      return error_to_text(message, log_error_trace_lines) if message.is_a?(Exception)

      message
    end

    def default_message_attrs(message, level)
      {
        message: format_message(message),
        level: level || level_from_message_type(message)
      }
    end

    def logger
      @logger ||= Logger.new(File.join(log_directory, log_file_name))
    end

    def log_directory
      Rails.root.join('log')
    end

    def log_file_name
      "#{self.class.name.underscore.tr('/', '_')}.log"
    end

    def log_error_trace_lines
      20
    end

    def info_error_trace_lines
      20
    end

    def error_to_text(error, trace_lines = 20)
      txt = "Error: #{error.message} (#{error.class})"
      txt << "Backtrace:\n#{error.backtrace[0, trace_lines].join("\n\t")}"
    end
  end
end
