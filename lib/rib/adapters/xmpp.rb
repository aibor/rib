# coding: utf-8

require 'rib'
require 'xmpp4r'
require 'xmpp4r/roster'
require 'xmpp4r/client'
require 'xmpp4r/muc'


class RIB::Adapters::XMPP

  include RIB::Adaptable
  include RIB::Connection::Logable

  autoload :Configuration, 'rib/adapters/xmpp/configuration'

  def initialize(config, log_path, debug = false)
    ::Jabber::debug = true if debug

    @hostname = config.server || config.jid.split('@').last
    @resource = config.resource
    @log_path = log_path
    jid = ::Jabber::JID.new(config.jid + "/" + @resource)
    @client = ::Jabber::Client.new(jid)
    @muc = {}

    login config.password
    config.muc.split(/\s+|\s*,\s*/).each do |muc|
      join_muc(muc)
    end
  end


  ##
  # @todo what a mess

  def run_loop
    start = Time.now
    @muc.each do |room,muc|
      muc.on_message do |time, nick, text|
        next if nick == @resource or start > (Time.now - 5)

        begin
          rib_msg = RIB::Message.new(text, nick, room)
          handler = RIB::MessageHandler.new(rib_msg) do |line|
            say line, muc
          end
          yield handler
        rescue
        end
      end
    end

    Thread.stop
  end


  def say(line, target)
    line.encode("utf-8")
    target.say(line) if target.is_a? ::Jabber::MUC::SimpleMUCClient
  end


  def quit(msg = 'Bye!')
    @muc.each_value {|m| m.say msg} if msg
    @client.close
  end


  private

  def join_muc(muc)
    mucjid = ::Jabber::JID.new "#{muc}@#{@hostname}/#{@resource}"
    @muc[muc.to_sym] = ::Jabber::MUC::SimpleMUCClient.new @client
    @muc[muc.to_sym].join mucjid
    add_ping_cb
  end


  def login(password)
    @client.connect
    @client.auth password
    @client.send ::Jabber::Presence.new.set_type(':available')
    togglelogging
  end


  def add_ping_cb
    @client.add_iq_callback do |iq_received|
      if iq_received.type == :get
        if iq_received.queryns.to_s != 'http://jabber.org/protocol/disco#info'
          iq = ::Jabber::Iq.new :result, @client.jid.node
          iq.id = iq_received.id
          iq.from = iq_received.to
          iq.to = iq_received.from
          @client.send iq
        end
      end
    end
  end

end

