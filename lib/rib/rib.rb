# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'
require 'logger'
load File.expand_path('../html/html.rb', __FILE__)

module RIB
   
  class Configuration
    Conf = Struct.new(:protocol, :server, :port, :ssl, :nick, :jid, :channel, :auth,
                      :tc, :password, :qmsg, :linkdump, :dumplink, :helplink,
                      :title, :pony, :verbose)
    SSL = Struct.new(:use, :verify, :ca_path, :client_cert)

    def initialize
      @config = default
    end

    def default # Default Configuration
      Conf.new(
        :irc,                                        # protocol
        'irc.quakenet.org',                          # server
				6667,																				 # port
        SSL.new( false,                              # use ssl? 
                 false,															 # ssl_verify
				         '/etc/ssl/certs',									 # ssl_ca_path
				         ''),	  														 # ssl_client_cert
        'rubybot' + rand(999).to_s,                  # nick
        'rubybot@xmpp.example.com',                  # jid
        '#rib',                                      # channel
        '',                                          # auth
        '!',                                         # tc
        'rib',                                       # password
        'Bye!',                                      # qmsg
        './yaylinks',                                # linkdump
        'http://www.linkdumpioorrrr.de',             # dumplink
        'https://github.com/aibor/rib/wiki',		     # helplink
        true,                                        # title
        false                                        # pony
      )                                         
    end
 
    def method_missing( meth, *args )
      meth = meth.to_s.sub(/=$/, '').to_sym
      if Conf.members.include? meth
        args.empty? ? @config[meth] : insert(meth, args.shift)
      else 
        super
      end
    end

    def insert( key, val )
      @config[key.to_sym] = val if @config.respond_to?(key)
    end

  end # class Config

  # Basisklasse für RIB-Module
  class MyModulesBase
    def initialize( bot )
      @bot = bot
    end 
  end

  # Klasse, die eingehende PRIVMSG auf trigger prüft
  class Message

    def initialize( bot, cmd )
      @bot, @cmd, @source = bot, cmd, cmd.prefix.match(/\A(.*?)!/)[1]  
    end

    def check
      output = Array.new(2)
      @bot.modules.each do |mod|
        if @cmd.last_param =~ mod.trigger
          out = mod.output(@source, $~, @cmd)
          output = out.is_a?(Array) ? out : [nil, out]
        end
      end
			if output[0].nil?
				if @cmd.params[0].include? "#"  
					output[0] = @cmd.params[0]
				else
					output[0] = @source 
				end
			end
      output
    end
  end # class Message

  class ConnectionBase
    Command = Struct.new(:prefix, :command, :params, :last_param)
    def initialize(host, *args)
      serverlogfile = File.expand_path("../../../log/#{host}.log", __FILE__)
			@logs = { :server => Logger.new(serverlogfile)}
			@logs[:server].level = Logger::INFO
      @logging = nil
      @me = String.new
    end

    def togglelogging
      @logging = @logging.nil? ? true : nil
    end
  end

  class Bot
    Command = Struct.new(:prefix, :command, :params, :last_param)

    attr_accessor :log, :config, :modules, :server, :starttime, :commands
    

    def initialize
      @config = Configuration.new
    end # initialize

    def configure
      yield @config
    end

    def protocol
      @config.protocol
    end

    def load_modules
      @modules = create_module_instances( File.expand_path( '../modules/', __FILE__ ) )
      get_commands
    end

    def create_module_instances( module_dir )
      readmoduledir( module_dir )
      mymodules = MyModules.constants.select { |m| MyModules.const_get(m).is_a? Class }
      mymodules.map {|mod| MyModules.class_eval( mod.to_s ).new( self ) }
    end

    def readmoduledir( moduledir )
      mods = Dir.glob(moduledir + "/*.rib.rb")
      if ! mods.empty?
        mods.each {|mod| load mod}
      end
    end

    def get_commands
      @modules.map do |mod|
        mod.trigger.to_s =~ /\\A#{@config.tc}\(?(?:\?\:)?(\w+(\|\w+|\s\w+)*)/
        next unless $1.respond_to? "split"
        $1.split(/\|/)
      end.delete_if(&:nil?)
    end

    def run
      # check for necessary params
      ["server", "channel", "nick"].each do |param|
        raise "No #{param} specified!" if @config.send(param).nil?
      end

      # Logfile for the Programm. NOT IRC log! Look into lib/irc.rb therefore.
      logfile = File.expand_path("../../../log/#{File.basename($0)}_#{@config.server}.log", __FILE__)
      destination = @config.verbose.nil? ? logfile : STDOUT
      @log = Logger.new(destination)
      @log.level = Logger::INFO

      load_modules

      begin
        @starttime = Time.new
        # Start IRC Connection
        @log.info( "Server starts" )

        @server = case self.protocol
                    when :irc then
                      require 'rib/irc'
                      IRC::Connection.new( @config.server, @config.nick, 
                                                        { :port	=> @config.port, 
                                                          :ssl   => @config.ssl.to_h } )
                    when :xmpp then
                      require 'rib/xmpp'
                      XMPP::Connection.new( @config.jid, @config.server, @config.nick )
                    else raise "Unknown protocol '#{self.protocol}'"
                  end

        @server.togglelogging
        @log.info( @server.login(@config.auth) )

        # iterate through channel list and join them
        @config.channel.split( /\s+|\s*,\s*/ ).each do |chan|
          @server.join_channel( chan )
          @log.info( "Connected to #{@config.server} as #{@config.nick} in #{chan}" )
        end

        # make the bot aware of himself 
        @server.setme( @config.nick )

        case self.protocol
          when :irc then run_irc
          when :xmpp then run_xmpp
          else raise "Unknown protocol '#{self.protocol}'"
        end

      rescue
        @log.fatal($!)
      ensure
        @log.info("EXITING")
        @log.close
      end # begin
    end # method run

    private

    def run_irc
        
      # After successful connection start with server response loop.
      while cmd = @server.recv
        begin

          # If a message is received check for triggers and response properly.
          if cmd.command == "PRIVMSG"
            msg = Message.new( self, cmd )
            output = msg.check
            # If useful response message was created: send it!
            next if output[1].nil?
            output[1] = output[1].scan(/.+/)
            output[1].each {|o| @server.privmsg(output[0], ":" + o); sleep(0.3)}
          end # if cmd.command
        rescue
          @log.error($!)
        end # begin
      end # while
    end

    def run_xmpp
    
      @server.muc.each do |room,muc|
        muc.on_message do |time,nick,text|
          begin
            raise if nick == @config.nick
            cmd = Command.new(nick + '!', 'PRIVMSG', ["room"], text) 
            msg = Message.new( self, cmd )
            output = msg.check
            muc.say(output[1].gsub(/(\|\[0-9,]+)/,'').gsub(/\/,':').encode("utf-8")) unless output[1].nil?
          rescue
            true
          end
        end
      end
      Jabber::debug = true

      Thread.stop
    end
  end # class Bot
end # module RIB
