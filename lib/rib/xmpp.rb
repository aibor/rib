# encoding: utf-8
#

require 'xmpp4r'
require 'xmpp4r/roster'
require 'xmpp4r/client'
require 'xmpp4r/muc'

module RIB
module XMPP

  class Connection < RIB::ConnectionBase

    attr_accessor :muc

    def initialize( jid, server, nick )
      @muc_server = server
      @resource = nick
      @client = Jabber::Client.new(Jabber::JID.new(jid + "/" + @resource))
      @muc = {}
      super
    end

    def login( password )
      @client.connect
      @client.auth( password )
      @client.send(Jabber::Presence.new.set_type(':available'))
    end

    def join_channel( channel )
      mucjid = Jabber::JID.new("#{channel}@#{@muc_server}/#{@resource}")
      p mucjid
      @muc[channel.to_sym] = Jabber::MUC::SimpleMUCClient.new(@client)
      @muc[channel.to_sym].join(mucjid)
      add_ping_cb
    end

    def setme( me )
      @me = me
    end

    private

    def add_ping_cb
      @client.add_iq_callback do |iq_received|
        if iq_received.type == :get
          if iq_received.queryns.to_s != 'http://jabber.org/protocol/disco#info'
            iq = Jabber::Iq.new(:result, @client.jid.node)
            iq.id = iq_received.id
            iq.from = iq_received.to
            iq.to = iq_received.from
            @client.send(iq)
          end
        end
      end
    end

  end
end
end
