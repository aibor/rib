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
        while cmd = @server.recv
          begin
            @log.info(cmd.to_a[0..-2].join(' ')) if self.debug

            # If a message is received check for triggers and response properly.
            if cmd.command == "PRIVMSG"
              user = cmd.prefix.match(/\A(.*?)!/)[1]
              @callbacks.each do |trigger,action|
                next unless cmd.last_param =~ trigger
                source = cmd.params[0].include?("#") ? cmd.params[0] : user
                out = action.call($~, user, cmd.last_param, source)
                case out
                when Array then say *out 
                when String then say out, source
                else true
                end
              end
            end # if cmd.command
          rescue
            @log.error($!)
          end # begin
        end # while
      end


      def server_say(line, target)
        @server.privmsg( target, ":" + line )
      end

    end
  end
end

