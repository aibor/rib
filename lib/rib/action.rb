# coding: utf-8

require 'rib/helpers'
require 'rib/action/handler'

module RIB

  class Action

    include Helpers

    ##
    # This instance's name. Should be unique for its Class.
    #
    # @return [Symbol]

    attr_reader :name


    ##
    # Short description of this instance for help texts.
    #
    # @return [String]

    attr_reader :description


    ##
    # Action block to call, if instance is invoked. See {#call} for
    # available methods and their values and also #call of the
    # instance's Class documentation for available additional Class
    # specific methods and values.
    #
    # @return [Proc]

    attr_reader :action


    ##
    # Name of the Module this instance belongs to.
    #
    # @return [Symbol]

    attr_reader :module


    ##
    # Protocols this instance is able to work with.
    #
    # @return [Symbol]

    attr_reader :protocol


    ##
    # Time of the last invocation of this instance's action block.
    #
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
    # @return [String]

    def desc(description)
      if description.respond_to? :to_s
        @description = description.to_s
      else
        raise TypeError, "doesn't respond to #to_s"
      end
    end


    private

    ##
    # @yield a block that is called on invocation of this instance.
    # @yieldreturn [String]            response to send back to the
    #                                  source the message was received
    #                                  from
    # @yieldreturn [(String, String)]  response and target to send back
    #                                  to
    # @yieldreturn [nil]               if nothing should be sent back
    #
    # @return [Proc]

    def on_call(&block)
      @action = block
    end


    ##
    # Call the block mapped to the action attribute of this instance.
    # The values passed as in the Hash will be available inside the
    # {Action::Handler} as methods with the name of the keys.
    #
    # @param [Hash] hash values that should be available in the Handler
    # @option hash [String] :msg    message that has been received
    # @option hash [String] :user   user that sent the message
    # @option hash [String] :source source of the message, e.g. the
    #                               channel
    # @option hash [Bot] :bot       the bot which received the message
    #
    # @return [String]            response to send back to the source
    #                             the message was received from
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
