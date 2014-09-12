# coding: utf-8

require 'rib/protocol/xmpp/connection'

module RIB

  module Protocol

    module XMPP

      def init_connection
        Connection.new(log_path,
                       @config.server,
                       @config.nick,
                       @config.jid)
      end


      private


      ##
      # @todo what a mess

      def run_loop
        Jabber::debug = true if @config.debug

        @connection.muc.each do |room,muc|
          muc.on_message do |time, nick, text|
            next if (nick == @config.nick) or (Time.new - @starttime < 5)
            begin
              out = process_msg(msg: text, user: nick, source: room)
              say([out].flatten[0], muc)
            rescue
              @log.error($!)
            end # begin
          end # muc.on_message
        end # @connection.muc.each

        Thread.stop
      end


      def server_say(line, target)
        line.encode("utf-8")
        target.say(line) if target.is_a? Jabber::MUC::SimpleMUCClient 
      end

    end

  end

end
