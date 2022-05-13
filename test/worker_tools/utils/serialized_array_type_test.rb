require 'test_helper'

describe WorkerTools::Utils::SerializedArrayType do
  let(:type) { WorkerTools::Utils::SerializedArrayType.new(type: WorkerTools::Utils::HashWithIndifferentAccessType.new) }

  describe 'deserializes' do
    it 'an array as json format' do
      assert_equal([{ 'foo' => 'bar' }], type.deserialize('[{"foo":"bar"}]'))
    end

    it 'a hash obj array with an key as symbol type' do
      assert_equal([{ 'foo' => 'bar' }], type.deserialize([{ foo: 'bar' }]))
    end
  end

  describe 'serializes' do
    it 'an array of hashes with indifferent access' do
      assert_equal('[{"foo":"bar","bar":"foo"}]', type.serialize([{ 'foo' => 'bar', bar: 'foo' }]))
    end

    it 'raises an error if the value is not an array' do
      err = assert_raises(StandardError) { type.serialize('foo') }
      assert_includes err.message, 'not an array'
    end
  end
end
