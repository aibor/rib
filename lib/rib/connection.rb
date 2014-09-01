# coding: utf-8

require 'logger'

module RIB::Connection

  Logging = Struct.new(:active, :path, :server, :channels, :level) do

    def add_channel_log(host, channel, loglevel = nil)
      self.channels ||= Hash.new

      logger = Logger.new self.path + host + "_#{channel}.log"
      logger.level = loglevel ? loglevel : self.level

      self.channels[channel] = logger
    end

  end


  class Base

    def initialize(log_path, host, *args)
			@logging = Logging.new(
        false,
        log_path,
        Logger.new(log_path + host + '.log'),
        Hash.new,
        Logger::INFO
      )

			@logging.server.level = @logging.level

      @me = String.new
    end


    def togglelogging
      @logging.active ^= true
    end

  end
end
