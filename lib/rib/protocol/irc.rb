# coding: utf-8

require 'rib'


module RIB::Protocol

  ##
  # IRC connection handling module.

  class IRC < Adapter

    autoload :Connection, "#{to_file_path(self.name)}/connection"


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
        yield get_handler(@connection, msg) if msg.command == "PRIVMSG"
      end
    end


    def say(line, target)
      @connection.privmsg(target, ":#{line}")
    end


    private

    def get_handler(connection, msg)
      handler = RIB::MessageHandler.new(msg.data, msg.user, msg.source)
      handler.tell { |line, target| say(line, target || msg.source) }
      handler
    end

  end

end

