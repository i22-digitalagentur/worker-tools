module WorkerTools
  module Utils
    class SerializedArrayType < ActiveRecord::Type::Json
      def initialize(type: nil)
        @type = type
      end

      def deserialize(value)
        super(value)&.map { |d| @type.deserialize(d) }
      end

      def serialize(value)
        raise 'not an array' unless value.is_a?(Array)

        super value
      end
    end
  end
end
