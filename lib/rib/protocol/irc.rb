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

        Connection.new(
          log_path,
          @config.server,
          @config.nick,
          {port: @config.port, ssl: ssl_hash}
        )
      end


      private

      def run_loop
        while cmd = @connection.recv 
          process_cmd cmd
        end
      end


      def process_cmd(cmd)
        @log.info(cmd.to_a[0..-2].join(' ')) if self.debug
        # If a message is received check for triggers and response properly.
        process_privmsg cmd if cmd.command == "PRIVMSG"
      end


      def process_privmsg(cmd)
        command, params = find_command cmd

        @log.info(cmd.to_a[0..-2].join(' ')) if self.debug

        return false unless command

        user, source = parse_cmd cmd

        case out = command.call(params, user, source)
        when Array  then say *out 
        when String then say out, source
        else true
        end
      rescue
        @log.error($!)
      end


      def parse_cmd(cmd)
        user    = cmd.prefix.match(/\A(.*?)!/)[1]
        source  = cmd.params[0][0] == '#' ? cmd.params[0] : user
      end


      def find_command(cmd)
        @modules.map(&:commands).flatten.each do |command|
          if cmd.last_param =~ /\A#{tc}#{command.name}\s+(.*)\z/
            return command, $1.split
          end
        end

        return false, []
      end


      def server_say(line, target)
        @connection.privmsg( target, ":" + line )
      end

    end
  end
end

