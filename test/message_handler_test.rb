# encoding: utf-8

require 'minitest/autorun'
require 'minitest/pride'
require 'rib/message_handler'
require 'rib/message'

class MessageHandlerTest < MiniTest::Test

  def setup
    @bot = RIB::Bot.new do |bot|
      bot.protocol  = :irc
      bot.server    = 'irc.example.org'
      bot.port      = 6667
      bot.channel   = '#test'
      bot.modules   = [:Core, :Fact]
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

