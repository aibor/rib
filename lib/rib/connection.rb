# coding: utf-8

require 'logger'


module RIB::Connection

  ##
  # This module may be included by classes that handle the connection
  # to a server. It provides methods for conveniently log messages
  # for server and channels seperately.

  module Logable

    ##
    # Handler of all logging instances.
    #
    # @param [String] log_path path of the log file directory
    # @param [String] hostname hostname of the server to connect to
    #
    # @return [Logging]

    def logging
      @logging ||= new_logging
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


    private

    def new_logging
      raise "'@log_path' not set" unless @log_path
      raise "'@hostname' not set" unless @hostname
      Logging.new(@log_path, @hostname)
    end

  end


  ##
  # This object is intended to manage the logging of the server and
  # channel messages. These are splitted in individual files.
  # The exact log file name is built based on the server
  # hostname and the respective channel name. All these files are
  # stored in the directory that is specified in {#path}.

  class Logging 

    ##
    # Current state of the instance. Is is currently logging or not?
    #
    # @return [Boolean]

    attr_accessor :active


    ##
    # Logger instance for server logs.
    #
    # @return [Logger]

    attr_reader :server


    ##
    # As each channel should have its own log, all these Logger
    # instances are handled individually.
    #
    # @return [Hash{Symbol => Logger}]

    attr_reader :channels


    ##
    # @param [String] path Path to the log file directory
    # @param [String] hostname hostname of the server

    def initialize(path, hostname)
      if not path.is_a?(String)
        raise TypeError, 'path is not a String'
      elsif not hostname.is_a?(String)
        raise TypeError, 'hostname is not a String'
      else
        @path     = path
        @hostname = hostname
        @server   = logger("#{path}#{hostname}.log")
        @channels = {}
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
      file_path = "#{@path}#{@hostname}_#{channel}.log"
      @channels[channel] = logger(file_path)
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

      return logger
    end

  end

end

