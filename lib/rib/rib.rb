# coding: utf-8

require "net/http"
require "uri"
require 'logger'
load File.expand_path('../html/html.rb', __FILE__)

module RIB

  class Configuration
    SSL = Struct.new(:use, :verify, :ca_path, :client_cert)

    def initialize
      @config = default
    end

    def method_missing( meth, *args )
      meth = meth.to_s.sub(/=$/, '').to_sym

      insert(meth, args.shift) unless args.empty?
      if @config.has_key? meth 
        @config[meth] 
      else
        super 
      end
    end

    def defined?( key )
      (@config.has_key?(key.to_sym) && ! @config[key.to_sym].nil?)
    end

    private

    def default # Default Configuration
      {
        protocol:   :irc,
        server:     'irc.quakenet.org',
				port:       6667,
        ssl:        SSL.new( false, false, '/etc/ssl/certs', '' ),
        nick:       'rib' + rand(999).to_s,
        jid:        'rubybot@xmpp.example.com',
        channel:    '#rib',
        tc:         '!',
        password:   'rib',
        qmsg:       'Bye!',
        title:      true,
        pony:       false,
        verbose:    false
      }
    end

    def insert( key, val )
      @config[key.to_sym] = val
    end

  end # class Config

  class ConnectionBase
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

    def initialize
      @config = Configuration.new
      yield @config
      
      # Logfile for the instance. NOT IRC log! Look into irc.rb therefore.
      logfile = "../log/#{File.basename($0)}_#{self.protocol}_#{self.server}.log"
      destination = self.verbose ? STDOUT : File.expand_path(logfile, $0)
      @log = Logger.new(destination)
      @log.level = Logger::INFO

      callbacks_init
    end

    def method_missing( *args )
      @config.send( *args )
    end

    def callbacks_init
      @callbacks = Hash.new
      eval(IO.read('lib/rib/callbacks.rb'), binding)
    end

    def add_response( trigger, &action )
      @callbacks[trigger] = action 
    end

    def run
      @starttime = Time.new

      # Start IRC Connection
      @log.info( "Server starts" )

      @server = case self.protocol
                when :irc then
                  require 'rib/irc'
                  ssl_hash = {}
                  @config.ssl.each_pair {|k,v| ssl_hash[k] = v }
                  IRC::Connection.new( @config.server, @config.nick,
                                      { :port	=> @config.port,
                                        # ruby1.9.3 - no to_h for Structs
                                        #:ssl   => @config.ssl.to_h } )
                                        :ssl   => ssl_hash } )
                when :xmpp then
                  require 'rib/xmpp'
                  XMPP::Connection.new( @config.jid, @config.server, @config.nick )
                else raise "Unknown protocol '#{self.protocol}'"
                end

      @server.togglelogging
      @log.info( @server.login(@config.defined?("auth") ? auth : nil) )

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
    end # method run

    def say( text, target )
      return if text.nil?
      text.split('\n').each do |line|
        next if line.empty?
        case self.protocol 
        when :irc then 
          @server.privmsg( target, ":" + line )
        when :xmpp then
          line.gsub!(/(\|\[0-9,]+)/,'')
          line.gsub!(/\/,':')
          line.encode("utf-8")
          target.say(line) if target.is_a? Jabber::MUC::SimpleMUCClient 
        end
      end
    end

    private

    def run_irc

      # After successful connection start with server response loop.
      while cmd = @server.recv
        begin

          @log.info(cmd.to_a[0..-2].join(' ')) if self.verbose

          # If a message is received check for triggers and response properly.
          if cmd.command == "PRIVMSG"
            user = cmd.prefix.match(/\A(.*?)!/)[1]
            @callbacks.each do |trigger,action|
              next unless cmd.last_param =~ trigger
              source = cmd.params[0].include?("#") ? cmd.params[0] : user
              out = action.call($~, user, cmd.last_param, source)
              case out.class.to_s
              when Array
                say *out 
              when String
                say out, source
              else
                true
              end
            end
          end # if cmd.command
        rescue
          @log.error($!)
        end # begin
      end # while
    end

    def run_xmpp

      Jabber::debug = true if self.verbose

      @server.muc.each do |room,muc|
        muc.on_message do |time,nick,text|
          next if nick == self.nick
          @callbacks.each do |trigger,action|
            begin
              next unless text =~ trigger
              say( action.call($~, nick, text, muc), muc )
            rescue
              @log.error($!)
            end # begin
          end
        end
      end

      Thread.stop
    end
  end # class Bot
end # module RIB
