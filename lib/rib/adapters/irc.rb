# coding: utf-8

require 'rib'


##
# IRC connection handling module.

class RIB::Adapters::IRC

  include RIB::Adaptable


  def initialize(config, log_path)
    # ruby1.9.3 - no to_h for Structs
    ssl_hash = config.ssl.members.inject({}) do |hash, key|
      hash.merge(key => config.ssl[key])
    end

    @connection = Connection.new(log_path, config.server, config.nick,
                                 {port: config.port, ssl: ssl_hash})
    @connection.login
    @connection.auth_nick(config.auth) if config.defined?(:auth)
    @connection.togglelogging
    config.channel.split(/\s+|\s*,\s*/).each do |chan|
      @connection.join_channel(chan)
    end
    @connection.setme(config.nick)
  end


  def quit(msg = 'Bye!')
    @connection.logging.active = false
    @connection.stop_ping_thread
    @connection.logout(msg)
  end


  def run_loop
    @connection.start_ping_thread

    while msg = @connection.receive

      next unless msg.command == "PRIVMSG"

      handler = RIB::MessageHandler.new(msg.to_rib_msg) do |line, target|
        say(line, target || msg.source)
      end

      yield handler

    end

  ensure
    @connection.stop_ping_thread rescue nil
  end


  def say(line, target)
    @connection.privmsg(target, ":#{line}")
  end

end

