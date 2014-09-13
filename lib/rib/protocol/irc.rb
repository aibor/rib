# coding: utf-8

require 'rib/protocol/irc/connection'

module RIB

  module Protocol

    ##
    # IRC connection handline module.

    module IRC

      ##
      # {IRC::Connection} instantiation wrapper.

      def init_connection
        # ruby1.9.3 - no to_h for Structs
        ssl_hash = @config.ssl.members.inject({}) do |hash, key|
          hash[key] = @config.ssl[key]
          hash
        end

        Connection.new(log_path,
                       @config.server,
                       @config.nick,
                       {port: @config.port, ssl: ssl_hash})
      end


      private

      def run_loop
        while msg = @connection.receive
          @log.debug msg.to_a[0..-2].join(' ')
          process_privmsg(msg) if msg.command == "PRIVMSG"
        end
      end


      def process_privmsg(msg)
        args = {
          msg: msg.data,
          user: msg.user,
          source: msg.source
        }

        case out = process_msg(args)
        when Array  then say *out
        when String then say out, msg.source
        else true
        end
      rescue => e
        @log.error e
      end


      def server_say(line, target)
        @log.debug "server_say: '#{line}' to '#{target}'"
        @connection.privmsg target, ":" + line
      end

    end

  end

end
