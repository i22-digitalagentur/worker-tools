module WorkerTools
  module Recorder
    def with_recording(&block)
      block.yield
    # this time we do want to catch Exception to attempt to handle some of the
    # critical errors.
    # rubocop:disable Lint/RescueException
    rescue Exception => e
      # rubocop:enable Lint/RescueException
      record_fail(e)
      raise
    end

    def with_logging(&block)
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
      record "ID #{model.id} - Error"
      record(error, :error)
      model.information = information
      model.save!(validate: false)
    end

    def add_log(message, level = :info)
      logger.public_send(level, format_log_message(message))
    end

    def add_info(message)
      @information ||= ''
      information << "#{format_info_message(message)}\n"
    end

    def record(message, level = :info)
      add_log(message, level)
      add_info(message)
    end

    def format_log_message(message)
      return error_to_text(message, log_error_trace_lines) if message.is_a?(Exception)
      message
    end

    def format_info_message(message)
      return error_to_text(message, info_error_trace_lines) if message.is_a?(Exception)
      message
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
