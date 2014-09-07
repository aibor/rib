# coding: utf-8

require 'rib/helpers'
require 'rib/action/handler'

module RIB

  class Action

    include Helpers

    ##
    # Command name
    #
    # @return [Symbol]

    attr_reader :name


    ##
    # Command description
    #
    # @return [String]

    attr_reader :description


    ##
    # Action to perform if action was triggered.
    #
    # @return [Proc]

    attr_reader :action


    ##
    # Name of the Module this command belongs to.
    #
    # @return [Symbol]

    attr_reader :module


    ##
    # Protocols this command is able to work with.
    #
    # @return [Symbol]

    attr_reader :protocol


    ##
    # @return [Time]

    attr_reader :last_call


    ##
    # @param [#to_sym] name
    #   name of the Command
    # @param [Symbol] mod_name
    #   name of the Module that Command belongs to
    # @param [Symbol, Array<Symbol>] protocol
    #   none or several protocols this command is limited to

    def initialize(name, mod_name, protocol = nil, &block)
      @name     = name.to_sym.downcase
      @module   = mod_name
      @protocol = protocol

      instance_eval &block

      @init = true
    end


    ##
    # Set description for this Action.
    #
    # @param [#to_s] description
    #
    # @return [void]

    def desc(description)
      if description.respond_to? :to_s
        @description = description.to_s
      else
        raise TypeError, "doesn't respond to #to_s"
      end
    end


    private

    ##
    # @param [Proc] block block to call on invocation of this Command
    # @return [void]

    def on_call(&block)
      @action = block
    end


    ##
    # Call the block mapped to the action for this Command.
    #
    # @param [Hash] hash values that should be available in the Handler
    # @option hash [String] :msg    message that has been sent
    # @option hash [String] :user   user that sent the message
    # @option hash [String] :source source of the message,
    #   e.g. the channel
    # @option hash [Bot] :bot       the bot which received the message
    #
    # @return [String]            response to send back
    # @return [(String, String)]  response and target to send back to
    # @return [nil]               if nothing should be sent back

    def call(hash)
      # Shall not be called from within the command definition itself.
      return false unless @init

      @last_call = Time.now

      handler = Handler.new(hash)
      handler.exec &@action
    end

  end

end
