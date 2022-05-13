class Import < ActiveRecord::Base
  enum state: { waiting: 0, complete: 1, failed: 2, complete_with_warnings: 3 }
end
