require 'active_support/concern'

module WorkerTools
  module Basics
    extend ActiveSupport::Concern

    included do
      attr_writer :model

      def self.wrappers(*args)
        @wrappers ||= args.flatten
      end

      def self.read_wrappers
        @wrappers || []
      end
    end

    def model_class
      # Ex: Import
      raise "model_class has to be defined in #{self}"
    end

    def model_kind
      # Ex: 'sdom'
      raise "model_kind has to be defined in #{self}"
    end

    def run
      raise "run has to be defined in #{self}"
    end

    def perform(model_id = nil)
      @model_id = model_id

      default_reset
      with_wrappers(wrapper_methods) do
        send(run_method)
      end
    end

    def wrapper_methods
      self.class.read_wrappers.map do |wrapper|
        symbolized_method = "with_wrapper_#{wrapper}".to_sym
        raise "Missing wrapper #{wrapper}" unless respond_to?(symbolized_method)

        symbolized_method
      end
    end

    def with_wrapper_basics(&block)
      custom_reset if respond_to?(:custom_reset, true)
      block.yield
      finalize
    # this time we do want to catch Exception to attempt to handle some of the
    # critical errors.
    # rubocop:disable Lint/RescueException
    rescue Exception => e
      # rubocop:enable Lint/RescueException
      return handle_empty_file(e) if e.is_a?(WorkerTools::Errors::EmptyFile)

      save_state_without_validate('failed')
      raise unless silent_error?(e)
    end

    def finalize
      mark_with_warnings = model.notes.any? do |note|
        complete_with_warnings_note_levels.include?(note.with_indifferent_access[:level].to_s)
      end

      model.update!(state: mark_with_warnings ? :complete_with_warnings : :complete)
    end

    def complete_with_warnings_note_levels
      %w[error warning]
    end

    def model
      @model ||= find_model
    end

    def with_wrappers(wrapper_symbols, &block)
      return yield if wrapper_symbols.blank?

      current_wrapper_symbol = wrapper_symbols.shift
      send(current_wrapper_symbol) { with_wrappers(wrapper_symbols, &block) }
    end

    def silent_error?(error)
      error.is_a?(WorkerTools::Errors::Silent)
      # or add your list
      # [WorkerTools::Errors::Silent, SomeOtherError].any? { |k| e.is_a?(k) }
    end

    def handle_empty_file(error)
      model.notes << { level: :info, message: error.message }
      model.state = 'empty'
      model.save!(validate: false)
    end

    private

    def run_mode
      model.try(:options).try(:[], 'run_mode').try(:to_sym)
    end

    def run_mode_option
      model.try(:options).try(:[], 'run_mode_option').try(:to_sym)
    end

    def run_method
      return :run unless run_mode.present?

      method_name = "run_in_#{run_mode}_mode"
      return method_name.to_sym if respond_to?(method_name, true)
      return :run if run_mode == :repeat # common fallback

      raise "Missing method #{method_name}"
    end

    def default_reset
      model.attributes = { notes: [], meta: {}, state: 'running' }
      model.save!(validate: false)
    end

    def save_state_without_validate(state)
      model.state = state
      model.save!(validate: false)
    end

    def find_model
      @model_id ||= nil
      return @model_id if @model_id.is_a?(model_class)
      return model_class.find(@model_id) if @model_id

      t = model_class.new
      t.kind = model_kind if t.respond_to?(:kind=)
      t.save!(validate: false)
      t
    end
  end
end
