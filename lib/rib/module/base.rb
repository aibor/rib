# coding: utf-8

require 'rib'


class RIB::Module::Base

  extend RIB::Helpers


  class << self

    ##
    # If the module can only be used with specific protocols, these
    # can be set in this attribute. If it works with all protocols,
    # it is nil.
    #
    # @return [Array<Symbol>] if it works with several protocols
    # @return [nil]           if it works with all protocols

    attr_reader :protocols


    def key
      name.split(':').last.to_sym
    end


    def descriptions
      @descriptions ||= {}
    end


    def commands
      public_instance_methods(false)
    end


    def responses
      @responses ||= {}
    end


    def protocol_blocks
      @protocol_blocks ||= Hash.new([])
    end


    def init_blocks
      @init_blocks ||= []
    end


    def timeouts
      @timeout ||= Hash.new(5)
    end


    private

    ##
    # Set a description for this module
    #
    # @param [#to_s] description
    #
    # @return [String] the description that has been set

    def describe(argument)
      case argument
      when String
        descriptions[nil] = argument
      when Hash
        argument.each do |cmd, desc|
          if cmd.respond_to?(:to_sym) && desc.respond_to?(:to_s)
            descriptions[cmd.to_sym] = desc.to_s 
          end
        end
      end
    end


    def register(hash)
      raise TypeError, 'not a Hash' unless hash.is_a? Hash

      hash.each do |config_key, default_value|
        if config_key.respond_to?(:to_sym)
          RIB::Configuration.register(config_key.to_sym, default_value)
        end
      end
    end


    def timeout(hash)
      raise TypeError, 'not a Hash' unless hash.is_a? Hash

      hash.each do |command, timeout|
        raise TypeError, 'not a Fixnum' unless timeout.is_a?(Fixnum)
        timeouts[command] = timeout
      end
    end


    def init(&block)
      init_blocks << block if init_blocks.none?(&:source_location)
    end


    ##
    # Define a response a bot should send if a message matches its
    # trigger. The name and the trigger regular expression are passed as
    # attributes. Further attributes are set in the mandatory block.
    # This block is evaluated in the instance namespace of the new
    # {Response} object. The on_call block will be evluated in an
    # {Action::Handler} instance namespace and therefor has a very
    # limited method list.
    #
    # @see Response#call for available methods in the on_call block
    #
    # @example
    #   response :marvin, /\bcrap\b/ do
    #     desc 'This bot is rather depressed'
    #     on_call do
    #       "#{user}: oh yes, everything is crap!"
    #     end
    #   end
    #
    # @param [#to_sym]  name    name of the {Response}
    # @param [Regexp]   trigger when this {Response} should be called
    #
    # @yield (see Action#on_call)
    # @yieldreturn (see Action#on_call)
    #
    # @raise [TypeError] if name is not a Symbol
    # @raise [TypeError] if name is not a Symbol
    # @raise [DuplicateResponseError] if name is not unique for this
    #                                 Module
    #
    # @return [Response] the created and added {Response}

    def response(hash)
      raise TypeError, 'not a Hash' unless hash.is_a? Hash

      hash.each do |name, trigger|
        if !name.respond_to?(:to_sym)
          raise TypeError, "not a symbolizable: #{name.inspect}"
        elsif !trigger.is_a?(Regexp)
          raise TypeError, "not a Regexp: #{trigger.inspect}"
        end
        responses[trigger] = name.to_sym
      end
    end


    ##
    # Limit the availability for the Module, Commands and Responses to
    # one or more protocols. When the Module itself is limited to
    # specific protocols, all of the passed ones need to be included in
    # the Module protocols.
    #
    # If no block is passed, the Module itself is limited to the passed
    # protocols.
    #
    # @param [Symbol, Array<Symbol>] protocols
    #
    # @yield limits the definitions within the block to protocol instead
    #   of the whole Module
    #
    # @raise [ProtocolMismatch] if the Module protocols doesn't contain
    #   one or more of the protocols passed
    #
    # @return [void]

    def protocols_only(*protocols, &block)
      ensure_symbol_or_array_of_symbols protocols

      return (@protocols = *protocols) unless block

      protocols.each do |protocol|
        if speaks?(protocol)
          array = protocol_blocks[protocol]
          array << block if array.none?(&:source_location)
        end
      end
    end

  end


  attr_accessor :new_msg

  attr_reader :bot, :msg_queue


  def initialize(bot)
    @bot, @new_msg, @msg_queue = bot, false, Queue.new

    self.class.protocol_blocks[bot.config.protocol].each do |block|
      logger.debug "protocol_block: #{block.source_location}"
      self.class.class_eval &block
    end

    self.class.init_blocks.each do |block|
      logger.debug "init: #{self.class.name}"
      instance_eval &block
    end
  end


  private

  def msg
    if @new_msg && !@msg_queue.empty?
      @new_msg = false
      @msg = @msg_queue.pop(true)
    else
      @msg
    end
  end


  def logger
    unless @logger
      @logger = bot.logger.dup
      @logger.progname = self.class.name
    end
    @logger
  end

end

