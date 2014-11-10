# coding: utf-8

require 'rib'
require "#{__dir__}/tcp_socket_mock"


RSpec.describe RIB::Protocol::IRC do
  include_examples 'tcp_socket_mock'
  include_examples 'bot instance', RIB::Protocol::IRC::Connection


  before do
    server.send(':localhost 001')
    server.send(':localhost 332')
    server.send(':localhost 311 rib')
    server.send(':localhost 318')
    server.send(':localhost PRIVMSG #rib :!ping')
    server.send(':localhost PRIVMSG #rib :!test')
    server.send(':localhost PRIVMSG #rib :!list')

    #wayne = Logger.new('/dev/null')
    wayne = Logger.new(STDOUT)
    allow(Logger).to receive(:new).and_return(wayne)
  end

  let(:bot) do
    bot = RIB::Bot.new do |b|
      b.protocol      = :irc
      b.logdir        = test_log_dir
      b.modules       = [:Core, :TestCore, :Reply]
      b.replies_file  = "#{test_dir}/replies.yml"
      b.debug         = true
    end

    bot.instance_eval { load_protocol_module }

    bot
  end


  describe '#process_privmsg' do
    let(:msg) do
      RIB::Protocol::IRC::Message.new(
        'rib!~rib@rib.users.example.org',
        'rib',
        '#rib',
        'PRIVMSG',
        %w(#rib !test),
        '!test'
      )
    end

    before do
      bot.instance_variable_set('@test_msg', msg)
    end
    subject { bot.instance_eval { process_privmsg(@test_msg) } }

    it 'calls process_msg' do
      expect(bot).to receive(:process_msg).
        with(RIB::Message.new('!test', 'rib', '#rib'), true).
        and_return(true)
      is_expected.to be true
    end
  end

  describe '#server_say' do
    it 'logs and shouts' do
      allow_message_expectations_on_nil
      expect(bot.instance_variable_get('@log')).to receive(:debug).
        with("server_say: 'yo' to '#rib'")
      expect(bot.instance_variable_get('@connection')).to \
        receive(:privmsg).with('#rib', ':yo')
      bot.instance_eval { server_say('yo', '#rib') }
    end
  end


    
  context 'from user perspective' do
    it 'runs and replies' do
      bot.run
      p bot.modules.keys
      sleep 0.1
      expect(server.received).to include('PRIVMSG #rib :pong')
      expect(server.received).to include('PRIVMSG #rib :yo')
      expect(server.received).to \
        include('PRIVMSG #rib :Available Modules: Core, TestCore')
    end
  end

end

