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
                        :socket_class => TCPSocket }.freeze
    COMMAND_METHODS = [:nick, :join, :privmsg, :user, :mode, :quit, :action].freeze

    def initialize( host, channel, options = Hash.new )
      options = DEFAULT_OPTIONS.merge(options)

      port ,@channel = options[:port], channel
      @irc_server  = options[:socket_class].new(host, port)
      @cmd_buffer = Array.new
      irclogfile = File.expand_path("../../log/#{host}_#{channel}.log", __FILE__)
      @irclog = Logger.new(irclogfile)
      @irclog.level = Logger::INFO
      @logging = nil
      @me = String.new
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
      raise "Auth error: #{authdata.to_s} not valid" if authdata.nil? or ! authdata.is_a? Array or authdata.length != 2
      privmsg(authdata[0], authdata[1])
      mode("#{nick} +x", " ")
      "auth sent"
    rescue
      $! 
    end

    def setme(me)
      mearr = whois(me).user.split(' ').shift(2)
      @me = ":" + me + "!" + mearr * "@" + " "
    end

    def join_channel
      join(@channel)

      rpl = recv_until do |c|
        c.command =~ /\A(?:461|47[13456]|40[35]|332|353)\Z/
      end
      if rpl.nil? or rpl.command !~ /\A3(?:32|53)\Z/
        raise "Join error:  #{rpl.last_param}."
      end
    end

    def transcoding( string )
      if RUBY_VERSION > '1.9'
        string.encode!("utf-8", "iso-8859-1") if string.encoding.name != "UTF-8"
      else
        string = Iconv.iconv("utf-8", "iso-8859-1", string).to_s
      end
      return string
    end

    def setlogging
      @logging = @logging.nil? ? true : nil
    end

    def irclog( msg )
      @logging.nil? ? nil : @irclog.info(msg.gsub(/||(\d,\d+)?/, ''))
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
      if not cmd.nil?
        if cmd =~ /:(\S+)!(?:\S+)\s(\w+)\s#{@channel}\s:(.*)/ and COMMAND_METHODS.include? $2.downcase.intern
        end
      end

      if not cmd.nil? and cmd =~ /\APING (.*?)\r\n\Z/
        send_command("PONG #{$1}")
        recv_command
      else
        irclog(transcoding(cmd.chop)) 
        cmd.nil? ? cmd : cmd.sub(/\r\n\Z/, "")
      end
    end

    def send_command( cmd )
      (cmd =~ /\A(?:PONG|WHOIS|PRIVMSG [^#])/).nil? ? irclog(@me + cmd) : nil
      @irc_server.print "#{cmd}\r\n"
    end

  end
end
