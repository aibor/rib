# coding: utf-8

require 'rib'


class RIB::Adapters::XMPP

  include RIB::Adaptable

  def initialize(config, log_path)
    Jabber::debug = true if config.debug

    @connection = Connection.new(
      log_path, config.server, config.nick, config.jid
    )
    @connection.login
    @connection.auth_nick(config.auth)
    @connection.togglelogging
    config.channel.split(/\s+|\s*,\s*/).each do |chan|
      @connection.join_channel(chan)
    end
  end


  ##
  # @todo what a mess

  def run_loop
    @connection.muc.each do |room,muc|
      muc.on_message do |time, nick, text|
        next if nick == @connection.resource

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
    target.say(line) if target.is_a? Jabber::MUC::SimpleMUCClient
  end

end

