#!/usr/bin/ruby -w
# coding = UTF-8
# Test class for irc.rb

require 'test/unit'
require File.expand_path('../../lib/irc.rb', __FILE__)
require File.expand_path('../../lib/rib.rb', __FILE__)
require File.expand_path('../mock/tcpsocket.rb', __FILE__)


class TestIRCConnection < Test::Unit::TestCase

  def setup
    test_construct
  end

  def test_construct
    @connex = IRC::Connection.new( "irc.quakenet.org", "#aibot",
                                    :socket_class => MockTCPSocket ) 
    assert_not_nil(@connex)
    assert_instance_of(IRC::Connection, @connex)
  end

  def test_recv
    #$server_responses << ":calvino.freenode.net 001 scribe " +
                         #":Welcome to the freenode IRC Network scribe"
    $server_responses << ":aiBot!~aiBot@aiBot.users.quakenet.org PRIVMSG #rigged :Moin!"
    cmd = @connex.recv
    puts cmd.inspect
    assert_not_nil(cmd)
    assert_instance_of(IRC::Connection::Command, cmd)
    assert_equal("#rigged", cmd.params[0])
    assert_equal("aiBot!~aiBot@aiBot.users.quakenet.org", cmd.prefix)
    assert_equal("PRIVMSG", cmd.command)
    assert_equal( ["#rigged", "Moin!"],
                 cmd.params )
    assert_equal( "Moin!",
                  cmd.last_param )
    #assert_equal("calvino.freenode.net", cmd.prefix)
    #assert_equal("001", cmd.command)
    #assert_equal( ["scribe", "Welcome to the freenode IRC Network scribe"],
                 #cmd.params )
    #assert_equal( "Welcome to the freenode IRC Network scribe",
                  #cmd.last_param )

    $server_responses << "TIME"
    cmd = @connex.recv
    assert_not_nil(cmd)
    assert_instance_of(IRC::Connection::Command, cmd)
    assert_nil(cmd.prefix)
    assert_equal("TIME", cmd.command)
    assert_equal(Array.new, cmd.params)
    assert_nil(cmd.last_param)
  end

end
