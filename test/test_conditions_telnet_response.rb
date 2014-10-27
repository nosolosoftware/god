require File.dirname(__FILE__) + '/helper'

class TestTelnetResponse < Test::Unit::TestCase
  def valid_condition
    c = Conditions::TelnetResponse.new()
    c.watch = stub(:name => 'foo')
    c.host = 'localhost'
    c.port = 8080
    c.timeout = 10
    c.times = 1
    c.command = 'show'
    yield(c) if block_given?
    c.prepare
    c
  end

  # valid?

  def test_valid_condition_is_valid
    c = valid_condition
    assert c.valid?
  end

  def test_valid_should_return_false_if_no_host_set
    c = valid_condition do |cc|
      cc.host = nil
    end
    assert !c.valid?
  end

  def test_valid_should_return_false_if_no_command_set
    c = valid_condition do |cc|
      cc.command = nil
    end
    assert !c.valid?
  end

  # test

  def test_test_should_return_true_if_response_times_out
    c = valid_condition

    obj = Object.new
    Net::Telnet.expects(:new).returns(obj)
    obj.expects(:cmd).raises(Timeout::Error, '')
    assert_equal true, c.test
  end

  def test_test_should_return_true_if_request_cant_connect
    c = valid_condition

    obj = Object.new
    Net::Telnet.expects(:new).returns(obj)
    obj.expects(:cmd).raises(Errno::ECONNREFUSED, '')
    assert_equal true, c.test
  end

  def test_test_should_return_false_if_only_of_one_in_two_conditions_are_not_meet
    c = valid_condition do |cc|
      cc.times = [1, 2]
    end

    obj = Object.new
    Net::Telnet.expects(:new).returns(obj).times(2)

    obj.expects(:cmd).returns("")
    assert_equal false, c.test

    obj.expects(:cmd).raises(Timeout::Error, '')
    assert_equal false, c.test
  end

  def test_test_should_return_true_if_only_one_of_two_in_three_conditions_are_not_meet
    c = valid_condition do |cc|
      cc.times = [2, 3]
    end

    obj = Object.new
    Net::Telnet.expects(:new).returns(obj).times(3)

    obj.expects(:cmd).returns(true)
    assert_equal false, c.test

    obj.expects(:cmd).raises(Timeout::Error, '')
    assert_equal false, c.test

    obj.expects(:cmd).raises(Timeout::Error, '')
    assert_equal true, c.test
  end
end
