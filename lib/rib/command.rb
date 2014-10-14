# coding: utf-8

require 'rib/helpers'
require 'rib/action'

module RIB

  ##
  # A Command is an object which handles a {Bot} command. If its name is
  # called, its action block is called. If it returns a String it is
  # sent back to the server.

  class Command < Action

    ##
    # Command params names. When a command is called, the params then
    # can be called by name from within the block.
    #
    # @return [Array<Symbol>]

    attr_reader :params


    ##
    # (see Action#initialize)
    # @param [Array<Symbol>] params
    #   params that command can take

    def initialize(name, modul, params = [], protocol = nil, &block)
      @params   = params.map(&:to_sym)

      super(name, modul, protocol, &block)
    end


    ##
    # (see Action#call)
    #
    # This is also the case for the params defined for the {Command}
    # instance.
    #

    def call(hash)
      #super hash.merge(params: map_params(hash[:msg].split[1..-1]))
      super hash.merge(params: hash[:msg].split[1..-1].take(@action.arity))
    end


    private

    ##
    # Map passed values to the params names of the command.
    #
    # @param [Array<String>] msg passed params
    #
    # @return [Hash]

    def map_params(msg)
      @params.each_with_index.inject({}) do |hash, (name, index)|
        hash.merge(name => msg[index])
      end
    end

  end

end
