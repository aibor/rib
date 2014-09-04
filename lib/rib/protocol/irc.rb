# coding: utf-8

require 'rib/protocol/irc/connection'

module RIB

  module Protocol

    module IRC

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
          process_msg msg
        end
      end


      def process_msg(msg)
        @log.debug msg.to_a[0..-2].join(' ')
        process_privmsg msg if msg.command == "PRIVMSG"
      end


      def process_privmsg(msg)
        return false unless command = find_command(msg)

        @log.debug "found command: #{command}; data: #{msg.data}"

        case out = command.call(msg.data, msg.user, msg.source, self)
        when Array  then say *out 
        when String then say out, msg.source
        else true
        end
      rescue
        @log.error($!)
      end


      def find_command(msg)
        self.commands.find do |cmd|
          msg.data[/\A#{tc}#{cmd.name}/]
        end
      end


      def server_say(line, target)
        @log.debug "server_say: '#{line}' to '#{target}'"
        @connection.privmsg target, ":" + line
      end

    end

  end

end
