# encoding: utf-8

require 'minitest/autorun'
require 'minitest/pride'
require 'rib/backlog'

class BacklogTest < MiniTest::Unit::TestCase

  def test_create
    backlog = RIB::Backlog.new(42)
    assert_equal 42, backlog.num
  end


  def test_add
    backlog = RIB::Backlog.new
    backlog.add(RIB::Message.new('test', 'me', '#test'))
    assert_equal 1, backlog.size
    assert_raises(TypeError) { backlog.add('M00') }
  end

end

