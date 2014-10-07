# coding: utf-8

require 'rib/protocol/irc/connection'
require "#{__dir__}/tcp_socket_mock"

RSpec.describe RIB::Protocol::IRC::Connection do
  include_examples 'tcp_socket_mock'
  include TestFilesSetup

  let(:conn) do
    RIB::Protocol::IRC::Connection.new(
      test_log_dir,
      'irc.example.com',
      'rib'
    )
  end

  let(:send_whois_me) do
    server.send(':localhost 311 rib rib ~rib 127.0.0.1 :rib')
    server.send(':localhost 319 rib rib :#test')
    server.send(':localhost 312 rib rib localhost :localhost')
    server.send(':localhost 330 rib rib rib :is authed as')
    server.send(':localhost 318 rib rib :End of /WHOIS list.')
  end

  let(:whois_me) do
    send_whois_me
    conn.whois('rib')
  end


  it_behaves_like 'connection'


  describe '#receive' do
    before do
      server.send('PING 1234')
      server.send(':rib!~rib@rib.users.example.org PRIVMSG #rib :Moin!')
    end

    let!(:msg) { conn.receive }

    it 'replies to ping and keep listening to messages' do
      expect(server.received.first).to eq('PONG 1234')
    end

    it 'receives messages' do
      expect(msg).to be_a(RIB::Protocol::IRC::Message)
    end

    it 'parses the message' do
      expect(msg.prefix).to   eq('rib!~rib@rib.users.example.org')
      expect(msg.user).to     eq('rib')
      expect(msg.source).to   eq('#rib')
      expect(msg.command).to  eq('PRIVMSG')
      expect(msg.params).to   eq(%w(#rib Moin!))
      expect(msg.data).to     eq('Moin!')
    end

    it 'raises RecivedError' do
      server.send('ERROR: m00')
      expect { conn.receive }.to raise_error RIB::ReceivedError
    end

  end


  describe '#login' do
    it 'sends nick and user' do
      server.send(':localhost 001')
      conn.login
      expect(server.received.first).to eq('NICK rib')
      expect(server.received.last).to \
        eq('USER rib hostname servername :rib')
    end

    it 'raises on error' do
      server.send(':localhost 431')
      expect { conn.login }.to raise_error(RIB::LoginError)
    end
  end


  describe '#auth_nick' do
    it 'raises without authdata' do
      expect { conn.auth_nick(nil) }.to raise_error(RIB::AuthError)
    end

    it 'sends auth data' do
      conn.auth_nick('nickserv identify 12345')
      expect(server.received.first).to \
        eq('PRIVMSG nickserv :identify 12345')
      expect(server.received.last).to eq('MODE rib +x')
    end
  end


  describe '#join_channel' do
    let(:join) { conn.join_channel('#test') }
    let(:join_success) { server.send(':localhost 332'); join }

    it 'sends JOIN command' do
      join_success
      expect(server.received.first).to eq('JOIN #test')
    end

    it 'raises on error' do
      server.send(':localhost 461')
      expect { join }.to raise_error(RIB::ChannelJoinError)
    end

    it 'adds logging instance' do
      expect { join_success }.to change { conn.logging[:channels].keys }.
        by(%w(#test))
    end
  end


  describe '#whois' do
    subject { whois_me }
    it { is_expected.to be_a(RIB::Protocol::IRC::User) }
  end


  describe '#setme' do
    subject { send_whois_me; conn.setme('rib') }
    it { is_expected.to be_a(String) }
    it { is_expected.to eq(':rib!~rib@127.0.0.1 ') }
  end

end
