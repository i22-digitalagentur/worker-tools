require 'active_support/concern'

module WorkerTools
  module Basics
    extend ActiveSupport::Concern

    included do
      attr_writer :model
      attr_accessor :information
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
      wrappers = [:with_basic_wrapper]
      wrappers << :with_rocketchat_error_notifier if respond_to?(:with_rocketchat_error_notifier)
      wrappers << :with_recording if respond_to?(:with_recording)
      with_wrappers(wrappers) do
        run
      end
    end

    def with_basic_wrapper(&block)
      block.yield
      finalize
    # this time we do want to catch Exception to attempt to handle some of the
    # critical errors.
    # rubocop:disable Lint/RescueException
    rescue Exception
      # rubocop:enable Lint/RescueException
      model.state = 'failed'
      model.save!(validate: false)
      raise
    end

    def finalize
      model.update_attributes!(
        state: 'complete',
        information: information
      )
    end

    def create_model_if_not_available
      false
    end

    def model
      @model ||= find_model
    end

    def with_wrappers(*wrapper_symbols, &block)
      wrapper_symbols.flatten!
      return yield if wrapper_symbols.blank?
      current_wrapper_symbol = wrapper_symbols.shift
      send(current_wrapper_symbol) { with_wrappers(wrapper_symbols, &block) }
    end

    private

    def find_model
      @model_id ||= nil
      return @model_id if @model_id.is_a?(model_class)
      return model_class.find(@model_id) if @model_id
      raise 'Model not available' unless create_model_if_not_available
      t = model_class.new
      t.kind = model_kind if t.respond_to?(:kind=)
      t.save!(validate: false)
      t
    end
  end
end
