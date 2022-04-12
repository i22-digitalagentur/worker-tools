module WorkerTools
  module Utils
    class HashWithIndifferentAccessType < ActiveRecord::Type::Json
      def deserialize(value)
        HashWithIndifferentAccess.new(super)
      end
    end
  end
end
