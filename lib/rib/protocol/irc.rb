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
        return false unless action = get_action(msg)

        @log.debug "found action: #{action}; data: #{msg.data}"

        case out = get_reply(action, msg)
        when Array  then say *out 
        when String then say out, msg.source
        else true
        end
      rescue => e
        @log.error e
      end


      def get_action(msg)
        if msg.data[0] == @config.tc
          find_handler(msg)
        else
          find_response(msg.data)
        end
      end


      def get_reply(action, msg)
        if [Command, Response].include? action.class
          action.call(msg: msg.data,
                      user: msg.user,
                      source: msg.source,
                      bot: self)
        elsif action.respond_to?(:sample)
          action.sample
        else
          action
        end
      end


      def find_handler(msg)
        name = msg.data[/\A#{@config.tc}(\S+)(?:\s+(\d+))?/, 1]
        find_command(name) || find_reply(name, $2)
      end


      def find_command(name)
        commands.find { |cmd| cmd.name == name.to_sym }
      end


      def find_reply(name, index = nil)
        reply = @replies[name]
        if index && reply.is_a?(Array) && reply.size > index.to_i
          reply[index.to_i]
        else
          reply
        end
      end


      def find_response(msg)
        responses.find { |resp| msg.match(resp.trigger) }
      end


      def server_say(line, target)
        @log.debug "server_say: '#{line}' to '#{target}'"
        @connection.privmsg target, ":" + line
      end

    end

  end

end
