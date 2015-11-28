# encoding: utf-8

require 'minitest/autorun'
require 'minitest/pride'
require 'rib/message_handler'
require 'rib/message'
require File.expand_path('../mock/module_mock.rb', __FILE__)


class MessageHandlerTest < MiniTest::Test

  def setup
    @bot = RIB::Bot.new(:irc) do |bot|
      bot.connection.server  = 'irc.example.org'
      bot.connection.port    = 6667
      bot.connection.channel = '#test'
      bot.modules   = ModuleMock
      bot.logdir    = '/tmp/log'
    end
    @bot.instance_variable_set(:@logger, Logger.new('/dev/null'))
    @bot.reload_modules
  end


  def get_handler(message)
    msg = RIB::Message.new(message, 'me', '#test')
    speaker = MiniTest::Mock.new
    msg_handler = RIB::MessageHandler.new(msg) do |line, target|
      speaker.say(line)
    end
    [msg_handler, speaker]
  end


  def test_process_for_command
    msg_handler, speaker = get_handler('!ergehtrhrhenrfd')
    speaker.expect(:say, nil, ["me: Unknown Command: 'ergehtrhrhenrfd'"])
    msg_handler.process_for(@bot)
  end


  def test_process_for_module
    msg_handler, speaker = get_handler('!Eefegegbtrrt#list')
    speaker.expect(:say, nil, ["me: Unknown Module: 'Eefegegbtrrt'"])
    msg_handler.process_for(@bot)
  end

end

