# coding: utf-8

require 'logger'
require 'yaml'
require 'rib/configuration.rb'
require 'rib/exceptions.rb'
require 'rib/module'


module RIB

  ##
  # Main class for initializing and handling the connection after reading
  # the configuration and initializing the callbacks. 
  #
  # @example
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

    ##
    # All currently defined commands

    attr_reader :config, :modules, :replies, :starttime, :connection


    def initialize
      yield @config = Configuration.new
      
      load_protocol_module

      # Logfile for the instance. NOT IRC log! Look into irc.rb for that
      init_log

      load_modules
      load_replies
    end


    ##
    # Make configuration attributes available as bot attributes.

    def method_missing(*args)
      @config.send(*args) or super
    end


    def commands
      @modules.map(&:commands).flatten.select do |command|
        command.speaks? @config.protocol
      end
    end


    def responses
      @modules.map(&:responses).flatten.select do |response|
        response.speaks? @config.protocol
      end
    end


    ##
    # After the bot irs configured and request handlers have been
    # loaded, the bot can initialize the connection and go into
    # its infinite loop.
    #
    # @return [void]

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


    def reload_modules
      load_modules
    rescue => e
      @log.error 'Exception catched while reloading modules:'
      @log.error e
      false
    end


    def reload_replies
      load_replies
    rescue => e
      @log.error 'Exception catched while reloading replies:'
      @log.error e
      false
    end


    def add_reply(trigger, value)
      return false unless reply_validation.call(trigger, value.to_s)

      @replies[trigger] = [@replies[trigger], value].flatten.compact
      save_replies
    end


    def delete_reply(trigger, index)
      return false unless @replies[trigger] and @replies[trigger][index]

      @replies[trigger].delete_at(index)
      save_replies
    end


    private

    def load_protocol_module
      protocol_path = "#{__dir__}/protocol/#{@config.protocol}.rb"

      require protocol_path

      extend RIB::Protocol.const_get(@config.protocol.to_s.upcase)
    #rescue LoadError
    #  raise UnknownProtocol.new(@config.protocol)
    end


    ##
    # After successful connection start with server response loop.

    def log_path
      file_path =  File.expand_path('..', $0)
      file_path << @config.logdir.sub(/\A\/?(.*?)\/?\z/, '/\1/')
    end


    def log_file_path
      log_path + "#{File.basename($0)}_#{self.protocol}_#{self.server}.log"
    end


    def init_log
      destination, level =
        if self.debug
          [STDOUT, Logger::DEBUG]
        else
          [log_file_path, Logger::INFO]
        end

      @log = Logger.new(destination)
      @log.level = level
    end


    ##
    # Load all modules in a file or a directory - specified in
    # \@config.modules.
    #
    # @return [void]

    def load_modules
      Module.load_path "#{__dir__}/modules/*.rb"

      modules = Module.loaded.select do |mod|
        @config.modules.include?(mod.name) && mod.speaks?(self.protocol)
      end

      @modules = modules
    end


    def load_replies
      hash = YAML.load_file(@config.replies)

      @replies = hash.select &reply_validation
      sanitize_replies
    end


    def sanitize_replies
      @replies = @replies.sort.to_h.inject({}) do |hash, (key, value)|
        value.compact! if value.respond_to?(:compact)
        hash[key] = [value].flatten if value && !value.empty?
        hash
      end
    end


    def save_replies
      sanitize_replies

      if File.writable?(@config.replies)
        File.write(@config.replies, @replies.to_yaml)  
      else
        false
      end
    end


    def reply_validation
      ->(name, value) do
        return false unless name.is_a? String

        if value.is_a? Array
          value.all? { |element| element.is_a? String }
        else
          value.is_a?(String)
        end
      end
    end


    ##
    # Start IRC Connection, authenticate and join all channels.
    #
    # @return [void]

    def init_server
      @log.info "Server starts"

      @connection = init_connection

      # Once the connection is established and the motd is done, all
      # further suff hould be logged
      @connection.togglelogging

      @connection.login
      @connection.auth_nick @config.auth if @config.defined?(:auth)

      join_channels

      # make the bot aware of himself
      @connection.setme @config.nick
    end


    ##
    # Iterate through channel list and join all of them.
    #
    # @return [void]

    def join_channels
      @config.channel.split( /\s+|\s*,\s*/ ).each do |chan|
        @connection.join_channel( chan )
        @log.info("Connected to #{@config.server} as #{@config.nick} in #{chan}")
      end
    end

  end # class Bot

end # module RIB
