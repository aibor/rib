# coding: utf-8

require 'rib/protocol/xmpp/connection'
require "#{__dir__}/jabber_mock"

RSpec.describe RIB::Protocol::XMPP::Connection do
  include_examples 'jabber_mock'
  include TestFilesSetup

  let(:conn) do
    RIB::Protocol::XMPP::Connection.new(
      test_log_dir,
      'muc.xmpp.example.com',
      'rib',
      'rib@xmpp.example.com'
    )
  end

  let(:client) { conn.instance_variable_get('@client') }

  it_behaves_like 'connection'


  describe '.new' do
    subject { conn }
    it { is_expected.to be_a(RIB::Protocol::XMPP::Connection) }
  end


  describe '#login' do
    it 'calls connect' do
      expect(client).to receive(:connect)
      conn.login
    end
  end


  describe '#auth_nick' do
    let(:auth) { conn.auth_nick('pw') }

    it 'calls auth' do
      expect(client).to receive(:auth).with('pw')
      auth
    end

    it 'sets presence' do
      auth
      expect(client.received).to be_a(JabberMock::Presence)
    end
  end


  describe '#quit' do
    let(:quit) { conn.quit('bye') }

    it 'tells mucs' do
      conn.join_channel('test_room')
      quit
      expect(conn.muc.values.first.received).to eq('bye')
    end

    it 'sends close' do
      expect(client).to receive(:close)
      quit
    end
  end


  describe '#join_channel' do
    it 'adds muc' do
      expect { conn.join_channel('test_room') }.to change \
        { conn.muc.keys }.by([:test_room])
      expect(client.received).to \
        be_a(JabberMock::Iq)
    end
  end

end

