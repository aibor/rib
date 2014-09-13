# coding: utf-8

require 'logger'

module RIB

  ##
  # Protocol independent object for connection handling. Provides a
  # class {Base}, which is intended to be inherited by {Protocol}
  # connection classes.

  module Connection

    ##
    # This object is intended to manage the logging of the {Protocol}
    # activities. These are divided in server logs and logs for each
    # channel. The exact log file name is built based on the server
    # hostname and the respective channel name. All these files are
    # stored in the directory that is specified in {#path}.
    #
    # @attr [String] path
    #   Path to the log file directory.
    # @attr [String] hostname
    #   Hostname of the server the {Bot} is connected to.
    # @attr [Fixnum] level
    #   Which messages to log. See
    #   {http://www.ruby-doc.org/stdlib-2.1.2/libdoc/logger/rdoc/Logger.html
    #   Logger documentation} for available values.
    # @attr [Boolean] active
    #   Current state of the instance. Is is currently logging or not?
    # @attr [Logger] server
    #   Logger instance for server logs.
    # @attr [Hash{Symbol => Logger}] channels
    #   As each channel should have its own log, all these Logger
    #   instances are handled individually.

    class Logging < Struct.new(:path, :hostname, :level, :active,
                               :server, :channels)

      ##
      # @param [String] path Path to the log file directory
      # @param [String] hostname hostname of the server
      # @param [Fixnum] loglevel Logger level; See
      #   {http://www.ruby-doc.org/stdlib-2.1.2/libdoc/logger/rdoc/Logger.html
      #   Logger documentation} for available values.


      def initialize(path, hostname, level = Logger::INFO)
        raise TypeError, 'path is not a String' unless path.is_a? String
        raise TypeError, 'hostname is not a String' unless hostname.is_a? String

        server_logger = Logger.new(path + hostname + '.log')
        server_logger.level = level

        super(path,
              hostname,
              level,
              false,
              server_logger,
              {})
      end


      ##
      # Create a now Logger instance for a channel. In order to build
      # the log file path, we need the server's hostname along with
      # the channel name.
      #
      # @param [#to_s] channel name of the channel
      # @param [Fixnum] loglevel Logger level for the now instance
      #
      # @return [Logger]

      def add_channel_log(channel, loglevel = nil)
        self.channels ||= Hash.new

        file_path = self.path + self.hostname + "_#{channel}.log"

        logger = Logger.new(file_path)
        logger.level = loglevel ? loglevel : self.level

        self.channels[channel] = logger
      end

    end


    ##
    # Base class for {Protocol} Connection classes. All protocol
    # independent methods should live here. This means methods related
    # to logging and error handling.

    class Base

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

    end

  end

end
