# coding: utf-8

require 'rib/message'

module RIB

  class Command

    ##
    # Command name

    attr_accessor :name


    ##
    # Our Bot instance

    attr_reader :bot


    ##
    # Command params

    attr_accessor :params


    ##
    # Command description

    attr_accessor :desc
    alias :desc :desc=


    ##
    # Action to perform if command was triggered.

    attr_reader :actions

    ##
    # Module name this command belongs to.

    attr_accessor :module
    alias :module :module=


    def initialize(name, bot, params = [], &block)
      @name   = name
      @bot    = bot
      @params = params

      instance_eval &block
    end


    def call(params, user, source)
      @actions[:on_call].call Message.new(params, user, source)      
    end


    def on_call(&block)
      @actions ||= {}

      @actions[:on_call] = block
    end

  end
end
