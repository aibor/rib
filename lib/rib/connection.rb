# coding: utf-8

require 'logger'


##
# Protocol independent object for connection handling.
# Base class for Connection classes. All protocol
# independent methods should live here. This means methods related
# to logging and error handling.

class RIB::Connection

  ##
  # Handler of all logging instances.
  #
  # @return [Logging]

  attr_reader :logging


  ##
  # @param [String] log_path path of the log file directory
  # @param [String] hostname hostname of the server to connect to
  # @param [Array] args protocol specific arguments

  def initialize(log_path, hostname, *args)
    @logging = Logging.new(log_path, hostname)

    @me = String.new
  end


  ##
  # Toggle logging on/off. Since Logging is disabled on connection
  # initialization, in order to discard MOTDs and stuff, it needs
  # to be switched on once initialization is done.
  #
  # @return [Boolean] logging active?

  def togglelogging
    @logging.active ^= true
  end


  ##
  # This object is intended to manage the logging of the server and
  # channel messages. These are splitted in individual files.
  # The exact log file name is built based on the server
  # hostname and the respective channel name. All these files are
  # stored in the directory that is specified in {#path}.
  #
  # @attr [String] path
  #   Path to the log file directory.
  # @attr [String] hostname
  #   Hostname of the server the {Bot} is connected to.
  # @attr [Boolean] active
  #   Current state of the instance. Is is currently logging or not?
  # @attr [Logger] server
  #   Logger instance for server logs.
  # @attr [Hash{Symbol => Logger}] channels
  #   As each channel should have its own log, all these Logger
  #   instances are handled individually.

  class Logging < Struct.new(:path, :hostname, :active, :server,
                             :channels)

    ##
    # @param [String] path Path to the log file directory
    # @param [String] hostname hostname of the server


    def initialize(path, hostname)
      if !path.is_a?(String)
        raise TypeError, 'path is not a String'
      elsif !hostname.is_a?(String)
        raise TypeError, 'hostname is not a String'
      else
        super(path, hostname, false, logger("#{path}#{hostname}.log"), {})
      end
    end


    ##
    # Create a now Logger instance for a channel. In order to build
    # the log file path, we need the server's hostname along with
    # the channel name.
    #
    # @param [#to_s] channel name of the channel
    #
    # @return [Logger]

    def add_channel_log(channel)
      file_path = "#{self.path}#{self.hostname}_#{channel}.log"
      self.channels[channel] = logger(file_path)
    end


    private

    ##
    # Create a imple Logger instance, which is intended for just
    # prefixing the server messages with a timestamp.
    #
    # @param file_path [String] path to the log file
    #
    # @return [Logger]

    def logger(file_path)
      logger = Logger.new(file_path)
      logger.formatter = proc do |severity, datetime, progname, message|
        "%s -- %s\n" % [datetime.strftime('%F %X'), message]
      end
      logger
    end

  end


  class Adapter

    extend RIB::Helpers

    attr_reader :connection

    def self.inherited(subclass)
      subclass.autoload :Connection,
        "#{to_file_path(subclass.name)}/connection"
    end

  end

end

