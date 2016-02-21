# coding: utf-8

require 'rib'


##
# IRC connection handling adapter.

class RIB::Adapters::IRC

  include RIB::Adaptable


  autoload :Connection, 'rib/adapters/irc/connection'
  autoload :Configuration, 'rib/adapters/irc/configuration'


  def initialize(config, log_path, debug = false)
    # ruby1.9.3 - no to_h for Structs
    ssl_hash = config.ssl.members.inject({}) do |hash, key|
      hash.merge(key => config.ssl[key])
    end

    @connection = Connection.new(config.server, config.nick, log_path,
                                 {port: config.port, ssl: ssl_hash})
    @connection.login
    @connection.auth_nick(config.auth) if config.auth
    @connection.togglelogging
    config.channels.each { |name, chan| @connection.join_channel(chan) }
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

