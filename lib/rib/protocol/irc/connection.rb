# coding: utf-8

require 'rib/connection.rb'
require 'socket'
require 'openssl'
require 'logger'
require 'date'

module RIB

  module Protocol

    module IRC

      Message = Struct.new :prefix, :user, :source, :command, :params,
        :data


      User = Struct.new :user, :channels, :server, :auth


      class Connection < RIB::Connection::Base

        NON_LOG_CMDS = %w(PONG WHOIS PRIVMSG)

        DEFAULT_OPTIONS = {
          port: 6667,
          ssl:  {
            use:      false, 
            ca_path:  '/etc/ssl/certs', 
            verify:   false, 
            cert:     false
          }
        }.freeze

        MESSAGE_METHODS = [
          :nick, :join, :privmsg, :user, :mode, :quit, :action, :part
        ].freeze


        def initialize(log_path, host, nick, options = Hash.new)
          options = DEFAULT_OPTIONS.merge options

          @host, @nick = host, nick

          tcp_socket = TCPSocket.new host, options[:port]

          @irc_server = if options[:ssl][:use]
                          ssl_connection tcp_socket, options[:ssl]
                        else
                          tcp_socket
                        end

          super
        end


        def ssl_connection(socket, options)

          ssl_context = OpenSSL::SSL::SSLContext.new

          if options[:cert]
            cert = File.read options[:cert]
            ssl_context.cert = OpenSSL::X509::Certificate.new cert
            ssl_context.key = OpenSSL::PKey::RSA.new cert
          end

          ssl_context.ca_path = options[:ca_path]

          const = options[:verify] ? VERIFY_PEER : VERIFY_NONE
          ssl_context.verify_mode = OpenSSL::SSL.const_get(const)

          ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
          ssl_socket.sync = true
          ssl_socket.connect

          return ssl_socket
        end


        def login
          nick @nick
          user @nick, 'hostname', 'servername', ":#{@nick}"

          rpl = receive_until do |c|
            c.command =~ /\A(?:43[1236]|46[12]|001)\Z/
          end

          raise LoginError, rpl.data unless rpl and rpl.command == "001"
        end


        def auth_nick(authdata)
          raise AuthError.new(authdata) unless authdata

          authdata = authdata.split(/\s+/)
          privmsg authdata.shift, authdata * ' '
          mode "#{@nick} +x", " "
          "auth sent"
        rescue
          $! 
        end


        def setme(me)
          mearr = whois(me).user.split.shift(2)
          @me = ":#{me}!#{mearr * '@'} "
        end


        def join_channel(channel)
          join channel

          rpl = receive_until do |c|
            c.command =~ /\A(?:461|47[13456]|40[35]|332|353)\Z/
          end

          unless rpl and rpl.command =~ /\A3(?:32|53)\Z/
            raise ChannelJoinError, rpl.data
          end

          @logging.add_channel_log @host, channel
        end


        def irclog(obj, level = :info)
          msg = obj.to_s
          target = if msg =~ /:(\S+)!(?:\S+)\s(\w+)\s((#\S+)\s)?:(.*)/ and $4
                     @logging.channels[$4]
                   else
                     @logging.server
                   end
          target.send(level, msg.gsub(/||(\d,\d+)?/, '')) if target
        end


        def receive
          msg = receive_message
          return msg if msg.nil? or msg.empty?

          unless msg =~ / \A
            (?::((?:([^!]+)!)?\S+)\s)?  # prefix and user
            ([A-Za-z]+|\d{3})           # command
            ((?:\s[^:]\S+)*)            # params, minus last
            (?:\s:?(.*))?               # data
            \Z /x
            raise MalformedMessageError, msg
          end

          params = $4.split + [$5].compact
          source = params[0][0] == '#' ? params[0] : $2

          Message.new($1, $2, source, $3, params, params.last)
        end


        def whois(user)
          send_message "WHOIS #{user}"

          out = User.new

          while msg = receive
            2.times {|i| msg.params.shift}
            case msg.command
            when /\A(?:311)\Z/ then out.user = msg.params * " "
            when /\A(?:319)\Z/ then out.channels = msg.params[0].split
            when /\A(?:312)\Z/ then out.server = msg.params * " "
            when /\A(?:330)\Z/ then out.auth = msg.params[0]
            when /\A(?:318)\Z/ then break
            end
          end

          return out
        end


        def receive_until
          while msg = receive
            return msg if yield msg
          end
        end


        def method_missing(meth, *args)
          if MESSAGE_METHODS.include? meth
            params     = args.dup
            params[-1] = ":#{params.last}" if params[-1] =~ /\A[^:].* /
            send_message "#{meth.to_s.upcase} #{params * ' '}"
          else
            super
          end
        end


        private

        def receive_message
          msg = @irc_server.gets

          if msg.nil? or msg.strip!.empty?
            msg
          elsif msg =~ /ERROR:.*/
            raise ReceivedError, msg 
          elsif msg =~ /\APING (.*?)\z/
            send_message("PONG #{$1}")
            receive_message
          else
            irclog msg
            msg
          end
        end


        def send_message(msg)
          if msg.nil? or msg.empty?
            irclog 'nothing to send given'
            return false
          elsif not non_log? msg
            irclog @me + msg
          end

          @irc_server.print "#{msg}\r\n"
        end


        ##
        # Check if a message is a IRC command that shouldn't be logged.
        #
        # @param  [String]  msg   string that should be checked
        # @return [Boolean] true  if it should not be logged 

        def non_log?(msg)
          !!(msg =~ /\A(?:#{NON_LOG_CMDS * '|'} [^#])/)
        end

      end
    end
  end
end
