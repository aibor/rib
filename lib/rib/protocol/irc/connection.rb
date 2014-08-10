# coding: utf-8

require 'rib/connection.rb'
require 'socket'
require 'logger'
require 'date'

module RIB
  module Protocol
    module IRC

      class Connection < RIB::Connection::Base
        Command = Struct.new :prefix, :command, :params, :last_param

        User = Struct.new :user, :channels, :server, :auth

        DEFAULT_OPTIONS = {
          socket_class: TCPSocket,
          port: 6667,
          ssl:  {
            use:      false, 
            ca_path:  '/etc/ssl/certs', 
            verify:   false, 
            cert:     false
          }
        }.freeze

        COMMAND_METHODS = [
          :nick, :join, :privmsg, :user, :mode, :quit, :action, :part
        ].freeze


        def initialize(log_path, host, nick, options = Hash.new)
          options = DEFAULT_OPTIONS.merge options

          @host, @nick, @cmd_buffer = host, nick, Array.new

          tcp_socket = options[:socket_class].new host, options[:port]
          @irc_server = if options[:ssl][:use]
                          ssl_connection tcp_socket, options[:ssl]
                        else
                          tcp_socket
                        end

          super
        end


        def ssl_connection(socket, options)
          require 'openssl'

          ssl_context = OpenSSL::SSL::SSLContext.new

          if options[:cert]
            ssl_context.cert = OpenSSL::X509::Certificate.new File.read(options[:cert])
            ssl_context.key = OpenSSL::PKey::RSA.new File.read(options[:cert])
          end

          ssl_context.ca_path = options[:ca_path]
          ssl_context.verify_mode = if options[:verify]
                                      OpenSSL::SSL::VERIFY_PEER
                                    else
                                      OpenSSL::SSL::VERIFY_NONE
                                    end

          ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
          ssl_socket.sync = true
          ssl_socket.connect

          return ssl_socket
        end


        def login(authdata = nil)
          nick @nick
          user @nick, 'hostname', 'servername', "\"#{@nick}\" RIB"

          rpl = recv_until {|c| c.command =~ /\A(?:43[1236]|46[12]|001)\Z/}
          raise LoginError, rpl.last_param unless rpl and rpl.command == "001"

          auth_nick authdata if authdata
        end


        def auth_nick(authdata)
          raise AuthError.new(authdata) unless authdata

          authdata = authdata.split(/\s+/)
          privmsg authdata.shift, authdata.join(' ')
          mode "#{@nick} +x", " "
          "auth sent"
        rescue
          $! 
        end


        def setme(me)
          mearr = whois(me).user.split(' ').shift(2)
          @me = ":" + me + "!" + mearr * "@" + " "
        end


        def join_channel(channel)
          join(channel)

          rpl = recv_until do |c|
            c.command =~ /\A(?:461|47[13456]|40[35]|332|353)\Z/
          end

          unless rpl and rpl.command =~ /\A3(?:32|53)\Z/
            raise ChannelJoinError, rpl.last_param
          end

          @logging.add_channel_log @host, channel
        end


        def transcoding( string )
          string.encode!("utf-8", "iso-8859-1") if string.encoding.name != "UTF-8"
          return string
        end


        def irclog( msg )
          target = if msg =~ /:(\S+)!(?:\S+)\s(\w+)\s((#\S+)\s)?:(.*)/ and $4
                     @logging.channels[$4]
                   else
                     @logging.server
                   end
          target ? target.info(msg.gsub(/||(\d,\d+)?/, '')) : nil
        end


        def recv
          cmd = recv_command
          return cmd if cmd.nil?

          cmd =~ / \A (?::([^\040]+)\040)?     # prefix
            ([A-Za-z]+|\d{3})        # command
            ((?:\040[^:][^\040]+)*)  # params, minus last
            (?:\040:?(.*))?          # last param
            \Z /x or raise "Malformed IRC command: #{cmd}"

            params = $3.split + ($4.nil? ? Array.new : [$4])
          Command.new($1, $2, params, params.last)
        end


        def whois(user)
          send_command "WHOIS #{user}"
          out = User.new
          while cmd = recv
            2.times {|i| cmd.params.shift}
            case cmd.command
            when /\A(?:311)\Z/ then out.user = cmd.params * " "
            when /\A(?:319)\Z/ then out.channels = cmd.params[0].split
            when /\A(?:312)\Z/ then out.server = cmd.params * " "
            when /\A(?:330)\Z/ then out.auth = cmd.params[0]
            when /\A(?:318)\Z/ then break
            end
          end
          return out
        end


        def recv_until
          skipped_commands = Array.new
          while cmd = recv
            if yield cmd
              @cmd_buffer.unshift(*skipped_commands)
              return cmd
            else
              skipped_commands << cmd
            end
          end
        end


        def method_missing( meth, *args, &block )
          if COMMAND_METHODS.include? meth
            params     = args.dup
            params[-1] = ":#{params.last}" if params[-1] =~ /\A[^:].* /
            send_command "#{meth.to_s.upcase} #{params.join(' ')}"
          else
            super
          end
        end


        private

        def recv_command
          cmd = @irc_server.gets
          return cmd if cmd.nil?
          raise cmd if cmd =~ /ERROR:.*/

          if cmd =~ /\APING (.*?)\r\n\Z/
            send_command("PONG #{$1}")
            recv_command
          else
            irclog(cmd.chop)
            cmd.sub(/\r\n\Z/, "")
          end
        end


        def send_command( cmd )
          irclog(@me + cmd) unless cmd =~ /\A(?:PONG|WHOIS|PRIVMSG [^#])/
          @irc_server.print "#{cmd}\r\n"
        end

      end
    end
  end
end
