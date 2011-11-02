# coding: utf-8

require "socket"
require "logger"
require "date"

module IRC

  class Connection
    Command = Struct.new(:prefix, :command, :params, :last_param)
    User = Struct.new(:user, :channels, :server, :auth)
    DEFAULT_OPTIONS = { :port         => 6667,
                        :socket_class => TCPSocket }.freeze
    COMMAND_METHODS = [:nick, :join, :privmsg, :user, :mode, :quit].freeze

    def initialize( host, channel, options = Hash.new )
      options = DEFAULT_OPTIONS.merge(options)

      port ,@channel = options[:port], channel
      @irc_server  = options[:socket_class].new(host, port)
      @cmd_buffer = Array.new
      irclogfile = File.expand_path("../../log/#{host}_#{channel}.log", __FILE__)
      @irclog = Logger.new(irclogfile)
      @irclog.level = Logger::INFO
      $Stats = Statistics.new(channel, irclogfile)
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

    def join_channel
      join(@channel)

      rpl = recv_until do |c|
        c.command =~ /\A(?:461|47[13456]|40[35]|332|353)\Z/
      end
      if rpl.nil? or rpl.command !~ /\A3(?:32|53)\Z/
        raise "Join error:  #{rpl.last_param}."
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
      if not cmd.nil?
        if cmd =~ /:(\S+)!(?:\S+)\s(\w+)\s#{@channel}\s:(.*)/ and COMMAND_METHODS.include? $2.downcase.intern
          $Stats.update($1, $2, $3)
          @irclog.info(cmd.chop) 
        end
      end

      if not cmd.nil? and cmd =~ /\APING (.*?)\r\n\Z/
        send_command("PONG #{$1}")
        recv_command
      else
        cmd.nil? ? cmd : cmd.sub(/\r\n\Z/, "")
      end
    end

    def send_command( cmd )
      if ! cmd.include? "PONG :"
        @irclog.info(cmd)
      end
      @irc_server.print "#{cmd}\r\n"
    end


  end

  class Statistics

    LOG_CMDS =[:privmsg, :join, :nick, :quit]

    def initialize( channel, irclogfile )
      @statsh = Hash.new
      @wordsh = Hash.new
      analyze_log(channel, irclogfile) if File.exist?(irclogfile)
    end

    def most( c, l )
      l = 0 if l.nil?
      most = @wordsh.reject {|k, v| k.length < l}.sort {|a, b| b[1]<=>a[1]}[0..c-1] 
      return nil if most.empty?
      @since.scan(/.+/) + most
    end

    def user( key )
      if key.is_a?(String)
        keyd = key.downcase
        @statsh[keyd].nil? ? nil : @statsh[keyd]
      else
        nil
      end
    end

    def update( usr, cmd, val, snc = local_date )
      if cmd == "PRIVMSG" and val.is_a?(String) and usr.is_a?(String)
        usr.downcase!
        wds = val.split
        wds.each {|w| 
          w.downcase! if ! w =~ /\A:.*/
          @wordsh[w].nil? ? @wordsh[w] = 1 : @wordsh[w] += 1 }
        wds = wds.length
        if ! @statsh.has_key? usr 
          @statsh[usr] = [snc, 1, wds]
        else
          @statsh[usr][1] += 1
          @statsh[usr][2] += wds
        end
      end
    end

    private

    def local_date ( dt = nil )
		 dt = Date.today().to_s if dt.nil?
      dt.sub(/(\d{4})-(\d{2})-(\d{2})/, '\3.\2.\1')
    end

    def analyze_log (channel, irclogfile)
      file = File.open(irclogfile, File::RDONLY | File::NONBLOCK)
      file.gets =~ /\A(?:# Logfile created on |., \[)(\d{4}-\d{2}-\d{2}).*\Z/
      @since, file.pos = local_date($1), 0
      file.each do |line|
        next if RUBY_VERSION > '1.9' and ! line.force_encoding("UTF-8").ascii_only?
        if line =~ /:(\S+)!(?:\S+)\s(\w+)\s#{channel}\s:(.*)/ and LOG_CMDS.include? $2.downcase.intern
          update($1, $2, $3, @since)
        end
      end
      file.close()
    end

  end
end
