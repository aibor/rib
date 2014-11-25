# coding: utf-8

require 'rib'


class RIB::Connection

  ##
  # IRC connection handling module.

  class IRC < Adapter

    def initialize(config, log_path)
      # ruby1.9.3 - no to_h for Structs
      ssl_hash = config.ssl.members.inject({}) do |hash, key|
        hash.merge(key => config.ssl[key])
      end

      @connection = Connection.new(
        log_path,
        config.server,
        config.nick,
        {port: config.port, ssl: ssl_hash}
      )
    end


    def run_loop
      while msg = @connection.receive
        next unless msg.command == "PRIVMSG"
        rib_msg = RIB::Message.new(msg.data, msg.user, msg.source)
        handler = RIB::MessageHandler.new(rib_msg) do |line, target|
          say(line, target || msg.source)
        end
        yield handler
      end
    end


    def say(line, target)
      @connection.privmsg(target, ":#{line}")
    end

  end

end

