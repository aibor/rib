# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'
require 'logger'
require 'rib/irc'
load File.expand_path('../html/html.rb', __FILE__)

module RIB
   
  class Configuration
    Conf = Struct.new(:irc, :port, :use_ssl, :ssl_verify, :ssl_ca_path, :ssl_client_cert, :nick, :channel, :auth, :tc, :password, :qmsg, :linkdump, :dumplink, :helplink, :title, :pony, :verbose)

    def initialize( file = String.new )
      @config = default
      cfile = File.expand_path("../../#{file}", __FILE__)
      File.exist?(cfile) ? read(cfile) : puts("File doesn't exist: " + cfile)
    end

    def default # Default Configuration
      Conf.new(
        "irc.quakenet.org",                          # irc
				6667,																				 # port
				nil,																				 # use_ssl
				nil,																				 # ssl_verify
				"/etc/ssl/certs",														 # ssl_ca_path
				nil,																				 # ssl_client_cert
        "rubybot" + rand(999).to_s,                  # nick
        "#rib",                                      # channel
        nil,                                         # auth
        "!",                                         # tc
        "rib",                                       # password
        "Bye!",                                      # qmsg
        "./yaylinks",                                # linkdump
        "http://www.linkdumpioorrrr.de",             # dumplink
        "https://github.com/aibor/rib/wiki",		     # helplink
        true,                                        # title
        nil                                          # pony
      )                                         
    end
 
    def read(cfile)
      file = File.open(cfile, File::RDONLY | File::NONBLOCK)
      file.each do |line|
        line =~ /\A\s*(#?)\s*(\w+)\s*(=\s*"?(.*?)"?\s*)?\Z/
        key, val = $2, $4
        next if $1 == "#" or key.nil?
        val = true if $3.nil?
        insert(key, val)
      end
      file.close
    end

    def update( file )
      read( file )
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

  class Bot

    attr_accessor :log, :config, :modules, :server, :starttime, :commands

    def initialize( config = Configuration.new )

      @config = config
      # check for necessary params
      ["irc", "channel", "nick"].each do |t|
        cmd = "@config." + t
        if (eval cmd).nil?
          puts "No #{t} specified!", "Type #{File.basename($0)} -h for help"
          exit
        end
      end

      # Logfile for the Programm. NOT IRC log! Look into lib/irc.rb therefore.
      logfile = File.expand_path("../../log/#{File.basename($0)}_#{@config.irc}.log", __FILE__)
      destination = @config.verbose.nil? ? logfile : STDOUT
      @log = Logger.new(destination)
      @log.level = Logger::INFO
      load_modules

    end # initialize

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
      begin
        @starttime = Time.new
        # Start IRC Connection
        @log.info( "Server starts" )
        @server = IRC::Connection.new( @config.irc, { :port			=> @config.port, 
                                                      :ssl	    => @config.use_ssl, 
                                                      :ca_path  => @config.ssl_ca_path, 
                                                      :verify		=> @config.ssl_verify, 
                                                      :cert			=> @config.ssl_client_cert } )
        @server.togglelogging
        @server.login( @config.nick, "hostname", "servername", "\"#{@config.nick}\" RIB" )
        @log.info( @server.auth_nick( @config.auth, @config.nick ) )
        
        # iterate through channel list and join them
        @config.channel.split( /\s+|\s*,\s*/ ).each do |chan|
          @server.join_channel( chan )
          @log.info( "Connected to #{@config.irc} as #{@config.nick} in #{chan}" )
        end

        # make the bot aware of himself 
        @server.setme( @config.nick )

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

      rescue
        @log.fatal($!)
      ensure
        @log.info("EXITING")
        @log.close
      end # begin
    end # method run
  end # class Bot
end # module RIB
