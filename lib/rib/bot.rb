# coding: utf-8

require 'rib/configuration.rb'
require 'rib/errors.rb'
require 'logger'

module RIB

  ##
  # Main class for initializing and handling the connection after reading
  # the configuration and initializing the callbacks. 
  #
  # Example:
  #
  #   require 'rib'
  #
  #   rib = RIB::Bot.new do |bot|
  #     bot.protocol  = :irc
  #     bot.server    = 'irc.quakenet.org'
  #     bot.port      = 6667
  #     bot.channel   = '#rib'
  #     bot.tc        = '!'
  #     bot.admin     = 'ribmaster'
  #     bot.debug     = true
  #   end
  #
  #   rib.run

  class Bot

    def initialize
      yield @config = Configuration.new
      
      protocol_path = "rib/protocol/#{@config.protocol}.rb"

      require protocol_path rescue UnknownProtocol.new(@config.protocol)
      extend RIB::Protocol.const_get(@config.protocol.to_s.upcase)
      # Logfile for the instance. NOT IRC log! Look into irc.rb for that
      init_log

      init_callbacks
    end


    ##
    # Make configuration attributes available as bot attributes.

    def method_missing(*args)
      @config.send(*args) or super
    end


    def add_response(trigger, &action)
      @callbacks[trigger] = action 
    end


    ##
    # After the bot irs configured and request handlers have been
    # loaded, the bot can initialize the connection and go into
    # its infinite loop.

    def run
      @starttime = Time.new

      init_server

      run_loop
    rescue => e
      @log.fatal($!)
    ensure
      @log.info("EXITING")
      @log.close
    end


    def say(text, target)
      return if text.nil?
      text.split('\n').each do |line|
        next if line.empty?
        server_say line, target
      end
    end


    private

    ##
    # After successful connection start with server response loop.

    def log_path
      file_path =  File.expand_path('..', $0)
      file_path << @config.logdir.sub(/\A\/?(.*?)\/?\z/, '/\1/')
    end


    def init_log
      destination, level = if self.debug
                             [STDOUT, Logger::DEBUG]
                           else
                             file_path =  log_path
                             file_path << File.basename($0)
                             file_path << "_#{self.protocol}"
                             file_path << "_#{self.server}.log"
                             [file_path, Logger::INFO]
                           end

      @log = Logger.new(destination)
      @log.level = level
    end


    def init_callbacks
      @callbacks = Hash.new
      eval(IO.read('lib/rib/callbacks.rb'), binding)
    end


    ##
    # Start IRC Connection, authenticate and join all channels.

    def init_server
      @log.info "Server starts"


      @server = init_connection

      # Once the connection is established and the motd is done, all
      # further suff hould be logged
      @server.togglelogging
      auth_to_server
      join_channels

      # make the bot aware of himself
      @server.setme @config.nick
    end


    ##
    # Iterate through channel list and join all of them.

    def join_channels
      @config.channel.split( /\s+|\s*,\s*/ ).each do |chan|
        @server.join_channel( chan )
        @log.info("Connected to #{@config.server} as #{@config.nick} in #{chan}")
      end
    end


    ##
    # Send the authentication string to the server if one is configured.

    def auth_to_server
      @log.info(@server.login(@config.defined?("auth") ? auth : nil))
    end

  end # class Bot
end # module RIB
