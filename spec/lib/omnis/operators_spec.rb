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
end
