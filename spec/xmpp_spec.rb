# coding: utf-8

require 'rib/connection/xmpp'


RSpec.describe RIB::Connection::XMPP do
  include_examples 'bot instance', RIB::Connection::XMPP::Connection

  before do
    wayne = Logger.new('/dev/null')
    allow(Logger).to receive(:new).and_return(wayne)
  end

  let(:bot) do
    bot = RIB::Bot.new do |b|
      b.protocol      = :xmpp
      b.logdir        = test_log_dir
      b.modules_dir   = "#{__dir__}/modules/",
      b.modules       = [:core],
      b.replies_file  = "#{test_dir}/replies.yml"
    end

    bot.instance_eval do
        adapter = get_connection_adapter(:xmpp)
        @connection_adapter = adapter.new(config, log_path)
        @connection = @connection_adapter.connection
    end

    bot
  end


  describe '#say' do
    it 'says to muc' do
      bot.instance_eval { @test_muc = Jabber::MUC::SimpleMUCClient.new('') }
      expect(bot.instance_variable_get('@test_muc')).to \
        receive(:say).with('yo')
      bot.instance_eval { say('yo', @test_muc) }
    end
  end

end
