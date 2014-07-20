#!/usr/bin/ruby -w
#
# Test class for irc.rb

require 'test/unit'
require 'rib'
require 'rib/connection/irc'
require File.expand_path('../mock/tcpsocket.rb', __FILE__)

class TestMyFuncs < Test::Unit::TestCase
  Conf = Hash[
    "qcmd", "quit",
    "host", "irc.quakenet.org",
    "channel", "#rubybot",
    "qmsg", "Bye!",
    "nick", "me",
    "most", 5,
    "title", 1,
    "pony", 1,
    "reps", Hash[
      "hi", "hallo",
    ],
  ]
  def setup
    $Stats = IRC::Statistics.new(Conf["channel"], File.expand_path("../../log/#{Conf["host"]}_#{Conf["channel"]}.log", __FILE__))
  end
  def test_most
    most = trigger("most", Conf)
    assert_kind_of(Array, most)
  end
  def test_say
    say = trigger("mesay WTF", Conf)
    assert_kind_of(String, say)
    assert_equal("WTF", say)
  end
  def test_resp
    resp = trigger("hi", Conf)
    assert_kind_of(String, resp)
    assert_equal("hallo", resp)
  end
  def test_set
    set = trigger("set title=0", Conf)
    assert_equal("title=0", set)
    set = trigger("set pony=0", Conf)
    assert_equal("pony=0", set)
  end
  def test_blank
    assert_nil(trigger("", Conf))
  end
end
