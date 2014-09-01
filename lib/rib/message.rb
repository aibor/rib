# coding: utf-8

module RIB

  ##
  # Received messages shall be parsed by the constructor of this
  # class and then be passed to a {Command#exec} block.

  class Message

    ##
    # All message attributes.

    attr_reader :params, :user, :source


    ##
    # @param [Hash] params
    #   Hash with params for the command. Keys depend on the command.
    # @param [String] user
    #   name of the user who sent the message
    # @param [String] source
    #   where did the message came from?
    #
    # @raise [TypeError] if the first argument is not a Hash
    # @raise [TypeError] if the second argument is not an Array

    def initialize(params, user, source)
      if params.is_a? Hash
        @params = params
      else
        raise TypeError, 'first argument is not a Hash'
      end

      @user   = user
      @source = source
    end

  end

end
