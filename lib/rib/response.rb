# coding: utf-8

require 'rib/helpers'
require 'rib/action'

module RIB

  class Response < Action

    ##
    # @return [Regexp]

    attr_reader :trigger


    ##
    # @param [#to_sym] name
    #   name of the Command
    # @param [Symbol] mod_name
    #   name of the Module that Command belongs to
    # @param [Regexp] trigger
    #   regular expression that triggers this Response
    # @param [Symbol, Array<Symbol>] protocol
    #   none or several protocols this command is limited to

    def initialize(name, mod_name, trigger, protocol = nil, &block)
      @trigger   = trigger

      super(name, mod_name, protocol, &block)
    end


    ##
    # Call the block mapped to the :on_call action for this Command.
    #
    # @param [String] data message that has been sent
    # @param [String] user user that sent the message
    # @param [String] source source of the message, e.g. the channel
    # @param [Bot] bot the bot which received the message
    #
    # @return [String]            response to send back
    # @return [(String, String)]  response and target to send back to
    # @return [nil]               if nothing should be sent back

    def call(data, user, source, bot)
      super(msg:    data,
            user:   user,
            source: source,
            match:  data.match(@trigger),
            bot:    bot)
    end

  end

end
