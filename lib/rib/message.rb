# coding: utf-8

module RIB

  ##
  # Received messages shall be parsed by the constructor of this
  # class and then be passed to a {Command#exec} block.

  class Message

    ##
    # All message attributes.

    attr_reader :message, :user, :source


    ##
    # @param [String] message
    #   message that was sent
    # @param [String] user
    #   name of the user who sent the message
    # @param [String] source
    #   where did the message came from?
    #

    def initialize(message, user, source)
      @message = message
      @user   = user
      @source = source
    end

  end

end
