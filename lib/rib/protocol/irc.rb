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
        while msg = @connection.receive 
          process_msg msg
        end
      end


      def process_msg(msg)
        @log.debug msg.to_a[0..-2].join(' ')
        process_privmsg msg if msg.command == "PRIVMSG"
      end


      def process_privmsg(msg)
        command, params = find_command msg

        @log.debug "found command: #{command}; params: " + 
        params.map{|k,v| "#{k}: #{v}"} * ', '

        return false unless command

        @log.debug msg
        out = command.call(params, msg.user, msg.source)
        @log.debug out
        case out
        when Array  then say *out 
        when String then say out, msg.source
        else true
        end
      rescue
        @log.error($!)
      end


      def find_command(msg)
        @modules.map(&:commands).flatten.each do |command|
          if msg.data =~ /\A#{tc}#{command.name}(?:\s+(.*))?\z/
            params = $1.to_s.split

            enum = command.params.each_with_index
            params_mapped = enum.inject({}) do |hash, (name, index)|
              hash.merge(name => params[index])
            end

            return command, params_mapped
          end
        end

        return false, []
      end


      def server_say(line, target)
        @log.debug "server_say: '#{line}' to '#{target}'"
        @connection.privmsg target, ":" + line
      end

    end

  end

end
