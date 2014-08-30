# coding: utf-8

require 'rib/protocol/xmpp/connection'

module RIB
  module Protocol
    module XMPP

      def init_connection
        Connection::XMPP.new(
          log_path,
          @config.server,
          @config.nick,
          @config.jid
        )
      end


      private

      def run_xmpp
        Jabber::debug = true if self.debug

        @connection.muc.each do |room,muc|
          muc.on_message do |time,nick,text|
            next if (nick == self.nick) or (Time.new - @starttime < 5)
            @callbacks.each do |trigger,action|
              begin
                next unless text =~ trigger
                say( action.call($~, nick, text, muc), muc )
              rescue
                @log.error($!)
              end # begin
            end # @callbacks.each
          end # muc.on_message
        end # @connection.muc.each

        Thread.stop
      end


      def server_say(line, target)
        line.gsub!(/(\|\[0-9,]+)/,'')
        line.gsub!(/\/,':')
        line.encode("utf-8")
        target.say(line) if target.is_a? Jabber::MUC::SimpleMUCClient 
      end

    end
  end
end

