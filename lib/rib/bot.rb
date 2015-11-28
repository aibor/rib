# coding: utf-8

require 'logger'
require 'fileutils'
require 'rib'


Thread.abort_on_exception = true


##
# Main class for initializing and handling the connection after
# reading the configuration and loading the {Module modules}.
# Based on the configuration, the Ruby modules for the appropriate
# protocol are loaded. This means the Bot behaves slightly differently
# for each protocol. Available protocols are defined in `protocols`
# directory.
# Since {Module Modules} can be limited to specific protocols, on
# invocation only those are loaded, which match the Bot instance's
# protocol.
#
# @example Basic Bot configuration
#   require 'rib'
#
#   rib = RIB::Bot.new(:irc) do |bot|
#     bot.server    = 'irc.quakenet.org'
#     bot.port      = 6667
#     bot.channel   = '#rib'
#     bot.admin     = 'ribmaster'
#     bot.modules   = [:Core, :Fun]
#   end
#
#   rib.run
#
# @see Configuration

class RIB::Bot

  ##
  # The Bot instance's {Configuration} object.
  #
  # @return [Configuration]

  attr_accessor :config


  ##
  # All loaded Modules for this Bot instance matching the bot's
  # protocol.
  #
  # @return [Array<Module>]

  attr_reader :modules


  ##
  # Boot time of the Bot instance. useful for calculating running
  # time.
  #
  # @return [Time]

  attr_reader :starttime


  ##
  # The Logger instance for this Bot instance.
  #
  # @return [Logger]

  attr_reader :logger


  ##
  # Backlog with 1000 last lines.
  #
  # @return [Backlog]

  attr_reader :backlog


  attr_reader :protocol

  ##
  # Create a new Bot instance. Configuration can be done via a passed
  # block directly or later on.
  #
  # @example with block
  #   rib = RIB::Bot.new(:irc) do |bot|
  #     bot.server    = 'irc.freenode.net'
  #     # ...
  #   end
  #
  # @example without block
  #   rib = RIB::Bot.new(:irc)
  #
  #   rib.config.server    = 'irc.freenode.net'
  #   # ...
  #
  # @see #configure
  #
  # @yieldparam config [Configuration]

  def initialize(protocol = :irc, &block)
    @protocol = protocol
    @connection_adapter = get_connection_adapter
    @logger = @startime = @connection = nil
    @threads = []
    @backlog = RIB::Backlog.new(1000)
    @config = RIB::Configuration.new @connection_adapter
    load_modules
    configure(&block) if block_given?
  end


  ##
  # Configure the Bot instance via a block, if it isn't running yet.
  #
  # @example
  #   rib = RIB::Bot.new
  #
  #   rib.configure do |bot|
  #     bot.protocol  = :irc
  #     bot.server    = 'irc.freenode.net'
  #     # ...
  #   end
  #
  # @yieldparam config [Configuration]

  def configure(&block)
    yield @config
  end


  ##
  # After the bot irs configured and request handlers have been
  # loaded, the bot can initialize the connection and go into
  # its infinite loop.
  #
  # @return [void]

  def run
    init_log # Logfile for the instance. NOT IRC log!

    @starttime = Time.new

    set_signals
    init_modules

    begin
      init_server

      @connection.run_loop do |handler|
        @backlog << handler.msg
        process_msg handler
      end

      @threads.each(&:join)
    rescue RIB::LostConnectionError => e
      disconnect rescue nil
      @logger.warn e.message
      sleep(2) && retry
    end
  rescue => e
    @logger.fatal e
  ensure
    @logger.info("EXITING")
  end


  ##
  # Output a message to a target (a user or channel). This calls the
  # #say method of the loaded connection adapter.
  #
  # @param text   [String] message to send, if multiline, then each
  #   line will be sent separately.
  # @param target [String] receiver of the message, a user or channel
  #
  # @return [nil]

  def say(text, target)
    return unless text || @connection
    text.split('\n').each do |line|
      next if line.empty?
      @logger.debug "say '#{line}' to '#{target}'" if @logger
      @connection.say line, target
    end
  end


  ##
  # Reload all modules. This is basically an alias to {#load_modules},
  # but catches and logs Exceptions. That's why it can be used for a
  # running instance, for example from a {Module} itself without
  # the possibility to kill the application, if {Module Modules} have
  # syntax errors or other issues.
  #
  # @return [Set<Module>] if successful
  # @return [FalseClass] if an exception was raised

  def reload_modules
    init_modules
  rescue => e
    @logger.error "Exception catched while reloading modules: "
    @logger.error e
    false
  end


  ##
  # Go away gracefully.
  #
  # @return [void]

  def quit
    disconnect
    exit
  end


  ##
  # Close the connection to the server.
  #
  # @return [void]

  def disconnect
    @connection.quit(@config.qmsg) if @connection
  end


  private

  ##
  # Catch some signals and close the connection gracefully, if it is
  # established already
  #
  # @raise [RuntimeError]
  #
  # @return [void]

  def set_signals
    %w(INT TERM).each do |signal|
      Signal.trap(signal) do
        quit
      end
    end
  end


  ##
  # Depending on the protocol the Bot instance has configured, the
  # appropriate connection adapter has to be loaded for connection
  # handling. The class name has to be te protocol name upcase and
  # has to be stored in a file with its name downcase with '.rb'
  # extension. Otherwise an exception is raised.
  #
  # @raise [LoadError] if file cannot be loaded
  #
  # @return[Object] a connection adapter

  def get_connection_adapter
    require "#{RIB::Adapters::PATH}/#{@protocol}"
    RIB::Adapters.const_get(@protocol.to_s.upcase)
  end


  ##
  # Build the path to the log directory depending on the value of
  # {Configuration#logdir}.
  #
  # @return [String] path to log directory

  def log_path
    path = @config.logdir[0] == '/' ? '' : File.expand_path('..', $0)
    path << @config.logdir.sub(/\A\/?(.*?)\/?\z/, '/\1/')

    FileUtils.mkdir_p path

    if File.writable?(path)
      return path
    else
      raise "#{path} not writable"
    end
  end


  ##
  # Build the path to the log file based on several {Configuration}
  # values for sane log file naming.
  #
  # @return [String] path of the log file

  def log_file_path
    name = "#{File.basename($0)}_#{@protocol}_#{@config.connection.server}"
    path = "#{log_path}#{name}.log"

    if not File.exist?(path) or File.writable?(path)
      path
    else
      raise "#{path} not writable"
    end
  end


  ##
  # Initialize the instance's logging instance. If
  # {Configuration#debug} is true, logging will be more verbose and
  # logs will go to STDOUT instead of a log file.
  #
  # @return [Boolean]

  def init_log
    destination       = @config.debug ? STDOUT : log_file_path
    @logger           = Logger.new(destination)
    @logger.progname  = self.class.name
    @logger.level     = @config.debug ? Logger::DEBUG : Logger::INFO

    @logger.formatter = proc do |severity, datetime, progname, message|
      time = datetime.strftime('%F %X.%L')
      format = "%-5s %s -- %s: %s\n"
      msg = Logger::Formatter.new.send(:msg2str, message)
      format % [severity, time, progname, msg]
    end

    @logger.info "Server starts"
  end


  ##
  # Load all modules in a file or a directory. {Module Modules} are
  # loaded from `rib/modules/` directories n `$LOAD_PATH` if their name
  # is listed in {Configuration#modules}. 
  #
  # @return [Set<Module>] all Modules for this Bot instance's
  #   protocol

  def load_modules
    mods = RIB::Module.load_all
    @config.modules = mods.inject({}) do |hash,mod|
      new_config = mod.defaults
      old_config = @config.modules[mod.key]
      if false == old_config
        hash.merge mod.key => false
      else
        if Struct === old_config
          old_config.each do |k,v|
            new_config[k] = v if new_config.members.include?(k)
          end
        end
        hash.merge mod.key => new_config
      end
    end
    @modules = RIB::ModuleSet.new(@config.modules, @protocol)
  end


  def init_modules
    load_modules
    @modules.each { |modul| modul.init(self) }
  end


  ##
  # Start IRC Connection, authenticate and join all channels.
  #
  # @return [void]

  def init_server
    @connection = @connection_adapter.new(@config.connection, log_path)
  end


  ##
  # Process a received message in background. To avoid resource
  # hogging, only allow 32 threads and ensure dead threads are cleaned
  # up.
  #
  # @param msg_handler [MessageHandler] 
  #
  # @return [Thread] if Thread could be created

  def process_msg(msg_handler)
    if @threads.size >= 32
      @logger.warn "too many threads"
      return false
    end

    @threads << Thread.new do
      begin
        msg_handler.process_for self
      ensure
        @threads.delete(Thread.current)
      end
    end
  end

end

