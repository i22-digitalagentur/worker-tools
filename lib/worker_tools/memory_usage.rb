require 'get_process_mem'

module WorkerTools
  module MemoryUsage
    extend ActiveSupport::Concern

    included do
      # rubocop:disable Metrics/MethodLength
      def with_wrapper_memory_usage(&block)
        memory_error = nil
        start_memory = GetProcessMem.new.mb

        begin
          block.call
        rescue StandardError => e
          memory_error = e
        ensure
          end_memory = GetProcessMem.new.mb
          memory_used = (end_memory - start_memory).round(2)
          model.meta['memory_usage'] = memory_used if model.respond_to?(:meta)
        end

        raise memory_error if memory_error
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
