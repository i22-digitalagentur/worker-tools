module WorkerTools
  Error = Class.new(StandardError)

  module Errors
    Silent = Class.new(Error)
    WrongNumberOfColumns = Class.new(Silent)
    DuplicatedColumns = Class.new(Silent)
    MissingColumns = Class.new(Silent)

    class EmptyFile < Silent
      def initialize(msg = 'The file is empty')
        super(msg)
      end
    end
  end
end
