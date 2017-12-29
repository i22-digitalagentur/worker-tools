class Import < ActiveRecord::Base
  enum state: { waiting: 0, complete: 1, failed: 2 }
end
