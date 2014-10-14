# coding: utf-8

require 'rib/helpers'
require 'rib/action/handler'

module RIB

  class Action

    include Helpers


    ##
    # Default Timeout for block execution in seconds.

    DEFAULT_TIMEOUT = 5


    class << self

      attr_accessor :timeout


    end

      self.timeout = DEFAULT_TIMEOUT

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
    # Module this instance belongs to.
    #
    # @return [Module]

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
    # Processing time in seconds allowed for execution of the action
    # block.
    #
    # @return [Fixnum]

    attr_reader :timeout


    ##
    # @param [#to_sym] name
    #   name of the Command
    # @param [Modul] modul
    #   name of the Module that Command belongs to
    # @param [Symbol, Array<Symbol>] protocol
    #   none or several protocols this command is limited to

    def initialize(name, modul, protocol = nil, &block)
      @name     = name.to_sym.downcase
      @module   = modul
      @protocol = protocol
      @timeout  = self.class.timeout

      instance_eval(&block)

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
    # @param timeout [Fixnum] timeout for exectuion of the block
    # @yield a block that is called on invocation of this {Action}
    #
    # @yieldreturn [String]            response to send back to the
    #                                  source the message was received
    #                                  from
    # @yieldreturn [(String, String)]  response and target to send back
    #                                  to
    # @yieldreturn [nil]               if nothing should be sent back
    #
    # @return [Proc]

    def on_call(timeout = Action.timeout, &block)
      @timeout = timeout if timeout.is_a?(Fixnum)
      @action = block
    end


    ##
    # Call the block mapped to the action attribute of this instance.
    # The values passed as in the Hash will be available inside the
    # {Action::Handler} as methods with the name of the keys.
    #
    # @!macro handler_tags
    #   @param [Hash] hash values that should be available in the Handler
    #   @option hash [String] :msg    message that has been received
    #   @option hash [String] :user   user that sent the message
    #   @option hash [String] :source source of the message, e.g. the
    #                               channel
    #   @option hash [Bot] :bot       the bot instance that received the
    #                               message
    #
    #   @return [String]            response to send back to the source
    #                               the message was received from
    #   @return [(String, String)]  response and target to send back to
    #   @return [nil]               if nothing should be sent back

    def call(hash)
      # Shall not be called from within the action definition itself.
      return false unless @init

      @last_call = Time.now

      handler = @module.handler
      handler.invocation_hash = hash
      handler.instance_exec(*hash[:params], &@action)
    end

  end

end
