# coding: utf-8

require 'logger'

module RIB::Connection

  class Base
    def initialize(host, *args)
      serverlogfile = File.expand_path("../../../log/#{host}.log", __FILE__)
			@logs = { :server => Logger.new(serverlogfile)}
			@logs[:server].level = Logger::INFO
      @logging = false
      @me = String.new
    end

    def togglelogging
      @logging = @logging ? false : true
    end
  end
end
