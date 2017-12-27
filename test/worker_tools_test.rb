require 'test_helper'

class WorkerToolsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::WorkerTools::VERSION
  end
end
