require 'test_helper'

describe WorkerTools::Utils::HashWithIndifferentAccessType do
  let(:type) { WorkerTools::Utils::HashWithIndifferentAccessType.new }

  describe 'deserialize' do
    it 'deserializes a json' do
      assert_equal({ 'foo' => 'bar' }, type.deserialize('{"foo":"bar"}'))
    end

    it 'deserializes a hash with a key as symbol type' do
      assert_equal({ 'foo' => 'bar' }, type.deserialize({foo: "bar"}))
    end
  end
end