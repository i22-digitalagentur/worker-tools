require 'test_helper'

describe WorkerTools do
  it 'has a version number' do
    refute_nil ::WorkerTools::VERSION
  end

  it 'models and schema should be loaded' do
    assert create_import
  end
end
