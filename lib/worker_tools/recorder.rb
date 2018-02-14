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

    def record_fail(error)
      record "ID #{model.id} - Error: #{error.message} (#{error.class})", :error
      trace = "Backtrace:\n#{error.backtrace.join("\n\t")}"
      record(trace, :error)
      model.information = information
      model.save!(validate: false)
    end

    def add_log(message, level = :info)
      log_file_name = "#{model_kind.underscore.tr('/', '_')}_#{model_class.name.underscore.tr('/', '_')}.log"
      @logger ||= Logger.new(File.join(log_directory, log_file_name))
      @logger.public_send(level, message)
    end

    def add_info(message)
      @information ||= ''
      @information << "#{message}\n"
    end

    def record(message, mode = :info)
      add_log(message, mode)
      add_info(message)
    end

    def log_directory
      Rails.root.join('log')
    end
  end
end
