module WorkerTools
  Error = Class.new(StandardError)

  module Errors
    Silent = Class.new(Error)
    WrongNumberOfColumns = Class.new(Silent)
    DuplicatedColumns = Class.new(Silent)
    MissingColumns = Class.new(Silent)
  end
end
