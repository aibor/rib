# coding: utf-8

require "socket"
require "logger"
require "date"
require "iconv" if RUBY_VERSION < '1.9'

module IRC

  class Connection
    Command = Struct.new(:prefix, :command, :params, :last_param)
    User = Struct.new(:user, :channels, :server, :auth)
    DEFAULT_OPTIONS = { :port         => 6667,
												:ssl					=> false, 
												:ca_path			=> "/etc/ssl/certs", 
												:verify				=> false, 
												:cert					=> false,
                        :socket_class => TCPSocket }.freeze
    COMMAND_METHODS = [:nick, :join, :privmsg, :user, :mode, :quit, :action, :part].freeze

    def initialize( host, options = Hash.new )
      options = DEFAULT_OPTIONS.merge(options)

      port ,@host = options[:port], host
      #@irc_server  = options[:socket_class].new(host, port)
      tcp_socket  = options[:socket_class].new(host, port)
			@irc_server = options[:ssl] ?	ssl_connection(tcp_socket, options) : tcp_socket
      @cmd_buffer = Array.new
      serverlogfile = File.expand_path("../../log/#{host}.log", __FILE__)
			@logs = { :server => Logger.new(serverlogfile)}
      #@serverlog = Logger.new(serverlogfile)
			@logs[:server].level = Logger::INFO
      #@serverlog.level = Logger::INFO
      @logging = nil
      @me = String.new
    end

		def ssl_connection(socket, options)
			require 'openssl'
			
			ssl_context = OpenSSL::SSL::SSLContext.new
			
			if options[:cert]
				ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(options[:cert]))
				ssl_context.key = OpenSSL::PKey::RSA.new(File.read(options[:cert]))
			end

			ssl_context.ca_path = options[:ca_path]
			ssl_context.verify_mode = options[:verify] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

			ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
			ssl_socket.sync = true
			ssl_socket.connect

			return ssl_socket
		end


    def login( nickname, host_name, server_name, full_name )
      nick(nickname)
      user(nickname, host_name, server_name, full_name)

      rpl = recv_until { |c| c.command =~ /\A(?:43[1236]|46[12]|001)\Z/ }
      if rpl.nil? or rpl.command != "001"
        raise "Login error:  #{rpl.last_param}."
      end
    end

    def auth_nick( authdata, nick )
      raise "Auth error: #{authdata} not valid" if authdata.nil?
      authdata = authdata.split(/\s+/)
      privmsg(authdata.shift, authdata.join(' '))
      mode("#{nick} +x", " ")
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
      if rpl.nil? or rpl.command !~ /\A3(?:32|53)\Z/
        raise "Join error:  #{rpl.last_param}."
      end
			channellogfile = File.expand_path("../../log/#{@host}_#{channel}.log", __FILE__)
			logname = channel.sub(/\A#/, 'c_').to_sym
			@logs[logname] = Logger.new(channellogfile)
			@logs[logname].level = Logger::INFO
    end

    def transcoding( string )
      if RUBY_VERSION > '1.9'
        string.encode!("utf-8", "iso-8859-1") if string.encoding.name != "UTF-8"
      else
        string = Iconv.iconv("utf-8", "iso-8859-1", string).to_s
      end
      return string
    end

    def togglelogging
      @logging = @logging.nil? ? true : nil
    end

    def irclog( msg )
			if msg =~ /:(\S+)!(?:\S+)\s(\w+)\s(#(\S+)\s)?:(.*)/ and ! $4.nil?
				target = "c_" + $4
				target = target.to_sym
			else
				target = :server
			end
			if @logs.has_key? target
				#@logging.nil? ? nil : @irclog.info(msg.gsub(/||(\d,\d+)?/, ''))
				@logging.nil? ? nil : @logs[target].info(msg.gsub(/||(\d,\d+)?/, ''))
			end
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
			raise cmd if cmd =~ /ERROR:.*/
      #if not cmd.nil?
        #if cmd =~ /:(\S+)!(?:\S+)\s(\w+)\s((#\S+)\s)?:(.*)/ #and COMMAND_METHODS.include? $2.downcase.intern
				#  puts cmd
				#  puts $3
        #end
      #end

      if not cmd.nil? and cmd =~ /\APING (.*?)\r\n\Z/
        send_command("PONG #{$1}")
        recv_command
      else
        return cmd if cmd.nil?
        #puts cmd.chop
        #puts transcoding(cmd.chop)
        #irclog(transcoding(cmd.chop)) 
        #if cmd =~ /:(\S+)!(?:\S+)\s(\w+)\s(#(\S+)\s)?:(.*)/
					#target = "c_" + $4
					#target = target.to_sym
				#else
					#target = :server
				#end
        irclog(cmd.chop) #if ! target.nil?
        cmd.sub(/\r\n\Z/, "")
      end
    end

    def send_command( cmd )
      (cmd =~ /\A(?:PONG|WHOIS|PRIVMSG [^#])/).nil? ? irclog(@me + cmd) : nil
      @irc_server.print "#{cmd}\r\n"
    end

  end
end
