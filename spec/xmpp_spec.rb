# coding: utf-8

require 'rib/protocol/xmpp'


RSpec.describe RIB::Protocol::XMPP do
  include_examples 'bot instance', RIB::Protocol::XMPP::Connection

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

    bot.instance_eval { load_protocol_module }

    bot
  end


  describe '#server_say' do
    it 'says to muc' do
      bot.instance_eval { @test_muc = Jabber::MUC::SimpleMUCClient.new('') }
      expect(bot.instance_variable_get('@test_muc')).to \
        receive(:say).with('yo')
      bot.instance_eval { server_say('yo', @test_muc) }
    end
  end

end
