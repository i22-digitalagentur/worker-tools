require 'active_support/concern'

module WorkerTools
  module Basics
    extend ActiveSupport::Concern

    included do
      attr_writer :model
      attr_accessor :information

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
      with_wrappers(wrapper_methods) do
        run
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

    def with_wrappers(wrapper_symbols, &block)
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
