require "spec_helper"
require "lyra_client/threadsafe_attributes"

describe "ThreadsafeAttributes" do

  class TestClass
    include ThreadsafeAttributes
    threadsafe_attribute :safeattr
  end

  before(:each) do
    @tester = TestClass.new
  end

  it "#threadsafe attributes work in a single thread" do
    expect(@tester).to respond_to(:safeattr_defined?)
    expect(@tester.safeattr).to be_nil
    @tester.safeattr = "a value"
    expect(@tester.safeattr).to_not be_nil
    expect(@tester.safeattr).to be == "a value"
  end

  it "#threadsafe attributes inherit the value of the main thread" do
    @tester.safeattr = "a value"
    Thread.new do
      expect(@tester.safeattr).to_not be_nil
      expect(@tester.safeattr).to be == "a value"
    end.join
    expect(@tester.safeattr).to be == "a value"
  end

  it "#changing a threadsafe attribute in a thread does not affect the main thread" do
    @tester.safeattr = "a value"
    Thread.new do
      @tester.safeattr = "a new value"
      expect(@tester.safeattr).to be == "a new value"
    end.join
    expect(@tester.safeattr).to be == "a value"
  end

  it "#threadsafe attributes inherit the value of the main thread when value is nil/false" do
    @tester.safeattr = false
    Thread.new do
      expect(@tester.safeattr).to_not be_nil
      expect(@tester.safeattr).to be == false
    end.join
    expect(@tester.safeattr).to be == false
  end

  it "#changing a threadsafe attribute in a thread sets an equal value for the main thread, if no value has been set" do
    expect(@tester).to respond_to(:safeattr_defined?)
    expect(@tester.safeattr).to be_nil
    Thread.new do
      @tester.safeattr = "value from child"
      expect(@tester.safeattr).to be == "value from child"
    end.join
    expect(@tester.safeattr).to_not be_nil
    expect(@tester.safeattr).to be == "value from child"
  end

end