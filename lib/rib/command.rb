# coding: utf-8

require 'rib/message'

module RIB

  class Command

    ##
    # Command name

    attr_reader :name


    ##
    # Command params

    attr_reader :params


    ##
    # Command description

    attr_accessor :desc
    alias :desc :desc=


    ##
    # Actions to perform if command was triggered.

    attr_reader :actions


    ##
    # Name of the Module this command belongs to.

    attr_reader :module


    ##
    # Protocols this command is able to work with.

    attr_reader :protocol


    def initialize(name, mod_name, params = [], protocol = nil, &block)
      @name     = name
      @params   = params
      @module   = mod_name
      @protocol = protocol

      instance_eval &block

      @init = true
    end


    def call(data, user, source, bot)
      # Shall not be called from within the command definition itself.
      return false unless @init

      msg     = Message.new data, user, source
      params  = map_params data.split[1..-1]

      @actions[:on_call].call msg, params, bot
    end


    def speaks?(protocol)
      raise TypeError, 'not a Symbol' unless protocol.is_a? Symbol

      case self.protocol
      when nil then true
      when Symbol then self.protocol == protocol
      when Array then self.protocol.include? protocol
      else false
      end
    end


    def on_call(&block)
      @actions ||= {}

      @actions[:on_call] = block
    end


    private

    def map_params(data)
      @params.each_with_index.inject({}) do |hash, (name, index)|
        hash.merge(name => data[index])
      end
    end

  end

end
