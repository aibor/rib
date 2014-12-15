# encoding: utf-8

#$LOAD_PATH.unshift File.expand_path('../mock', __FILE__)

require 'rib/bot'

#old_verbose = $VERBOSE
#$VERBOSE = nil
#$VERBOSE = old_verbose


class TestBot < MiniTest::Unit::TestCase

  def setup
    @bot = RIB::Bot.new do |bot|
      bot.protocol  = :irc
      bot.server    = 'irc.example.org'
      bot.port      = 6667
      bot.modules   = [:Core, :Fact]
    end
  end


  def test_construct
    assert_instance_of(RIB::Configuration, @bot.config)
    assert_equal(RIB::ModuleSet.new([]), @bot.modules)
  end

end

