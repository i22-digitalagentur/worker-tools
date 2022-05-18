module WorkerTools
  Error = Class.new(StandardError)

  module Errors
    Invalid = Class.new(Error)
    WrongNumberOfColumns = Class.new(Invalid)
    DuplicatedColumns = Class.new(Invalid)
    MissingColumns = Class.new(Invalid)
  end
end
