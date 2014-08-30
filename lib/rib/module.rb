# coding: utf-8

require 'rib/command'

module RIB

  class Module

    @@bot = nil


    attr_reader :name, :bot, :desc, :commands


    def initialize(name, &block)
      raise "@@bot isn't set yet" unless @@bot

      @name     = name.to_s
      @bot      = @@bot
      @commands = []

      if @bot.modules.bsearch {|m| m.name == @name}
        raise DuplicateModuleError
      else
        instance_eval &block
        @bot.modules << self
      end
    end


    class << self

      def bot(bot)
        if bot.is_a? RIB::Bot
          @@bot = bot
        else
          raise TypeError, 'is not a RIB::Bot'
        end
      end

      alias :bot= :bot

    end


    private

    def connection
      @bot.connection
    end


    def desc(description)
      @description = description
    end


    def command(name, *params, &block)
      cmd = Command.new name, @bot, params, &block
      cmd.module = @name

      self.commands << cmd
    end


    def protocol(protocol_name)
      yield if block_given? and bot.protocol == protocol_name
    end

  end
end
