require 'spec_helper'
require 'omnis/operators'

describe Omnis::Operators do
  it 'supports equality' do
    this = Omnis::Operators::NullOperator.new(:key, :value)
    that = Omnis::Operators::NullOperator.new(:key, :value)
    (this == that).should be_true

    other = Omnis::Operators::NullOperator.new(:other, :value)
    (other == this).should be_false

    another = Omnis::Operators::NullOperator.new(:key, :another)
    (another == this).should be_false
  end

  it 'should carry additional options' do
    o = Omnis::Operators::NullOperator.new(:key, :value, {:k => 'v'})
    expect(o.key).to   eq(:key)
    expect(o.value).to eq(:value)
    expect(o.opts).to  eq({:k => 'v'})
  end

  describe '::parse_value' do
    class IntegerOperatorTest < Omnis::Operators::Equals
      def self.parse_value(value)
        Integer(value)
      end
    end

    it 'supports custom value parsing' do
      age = IntegerOperatorTest.new(:age, '10')
      age.value.should == 10
    end
  end
end
