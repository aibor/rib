#!/usr/bin/ruby -w
# coding = UTF-8
# Test class for irc.rb

require 'test/unit'
require File.expand_path('../../lib/irc.rb', __FILE__)
require File.expand_path('../../lib/myfuncs.rb', __FILE__)
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
    $server_responses << ":calvino.freenode.net 001 scribe " +
                         ":Welcome to the freenode IRC Network scribe"
    cmd = @connex.recv
    assert_not_nil(cmd)
    assert_instance_of(IRC::Connection::Command, cmd)
    assert_equal("calvino.freenode.net", cmd.prefix)
    assert_equal("001", cmd.command)
    assert_equal( ["scribe", "Welcome to the freenode IRC Network scribe"],
                 cmd.params )
    assert_equal( "Welcome to the freenode IRC Network scribe",
                  cmd.last_param )

    $server_responses << "TIME"
    cmd = @connex.recv
    assert_not_nil(cmd)
    assert_instance_of(IRC::Connection::Command, cmd)
    assert_nil(cmd.prefix)
    assert_equal("TIME", cmd.command)
    assert_equal(Array.new, cmd.params)
    assert_nil(cmd.last_param)
  end

  def test_stats
    output = $Stats.most(3)
    #assert_kind_of(Array, output)
    assert_nil(output)
    #assert_equal([".*", 7], output[4])
  end

  def test_title
    title = title("http://www.xkcd.com/278")
    puts title
    title = title("http://www.deviantart.com")
    puts title
    title = title("http://www.youtube.com")
    puts title
    title = title("https://sash0.deviantart.com/art/Team-Lilac-40737687?q=gallery%3Asash0&qo=212")
    puts title
  end

  def test_gsearch
    key = 'drücken & lästern'
    out = gsearch(key)
    puts out
  end
  
end
