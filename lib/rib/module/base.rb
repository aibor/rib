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


    def inherited(subclass)
      RIB::Module.loaded << subclass
    end


    def key
      name.split(':').last.to_sym
    end


    def protocol_blocks
      @protocol_blocks ||= Hash.new([])
    end


    def init_blocks
      @init_blocks ||= []
    end


    def commands
      public_instance_methods(false)
    end


    def descriptions
      @descriptions ||= {}
    end


    def timeouts
      @timeout ||= Hash.new(5)
    end


    def triggers
      @triggers ||= {}
    end


    def has_command_for_args?(command_name, args_count)
      unless public_instance_methods(false).include?(command_name)
        return false 
      end

      method = instance_method(command_name)
      params = method.parameters.group_by(&:first)

      return true if params[:rest]

      args_min = params[:req].to_a.count
      args_max = args_min + params[:opt].to_a.count

      args_count.between?(args_min, args_max)
    end


    def init(bot)
      init_blocks.each do |block|
        block.call(bot)
      end
    end


    private

    def register(hash)
      raise TypeError, 'not a Hash' unless hash.is_a? Hash

      hash.each do |config_key, default_value|
        if config_key.respond_to?(:to_sym)
          RIB::Configuration.register(config_key.to_sym, default_value)
        end
      end
    end


    def on_init(&block)
      init_blocks << block if init_blocks.none?(&:source_location)
    end


    ##
    # If a String is passed, sets the description for the RIB::Module.
    # If a Hash is passed, it sets descriptionis for the {RIB::Command
    # commands with the name of the keys.
    #
    # @see #descriptions
    #
    # @param argument [String, Hash{Symbol => #to_s}]
    #
    # @return [String, Hash] the description that has been set
    #

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


    def timeout(hash)
      raise TypeError, 'not a Hash' unless hash.is_a? Hash

      hash.each do |command, timeout|
        raise TypeError, 'not a Fixnum' unless timeout.is_a?(Fixnum)
        timeouts[command] = timeout
      end
    end


    ##
    # Define a response a bot should send if a message matches the
    # trigger. The block is evaluated in the instance scope of the
    # bot module it belongs to, which shall inherit from
    # {RIB::Module::Base}.
    #
    # @example
    #   response /\bcrap\b/ do
    #     "#{msg.user}: oh yes, everything is crap!"
    #   end
    #
    # @param regexp [Regexp] when to be invoked
    #
    # @yield 
    # @yieldreturn [String, [String, String]]
    #
    # @raise [TypeError] if regexp is not a Regexp
    #
    # @return [Proc] the block
    #

    def trigger(regexp, timeout = nil, &block)
      if regexp.is_a?(Regexp)
        triggers[regexp] = block
        timeouts[regexp] = timeout.to_i if timeout
      else
        raise TypeError, "not a Regexp: #{regexp.inspect}"
      end
    end

  end


  attr_reader :bot, :msg


  def initialize(bot, msg)
    @bot, @msg = bot, msg
  end


  private

  def logger
    unless @logger
      @logger = bot.logger.dup
      @logger.progname = self.class.name
    end
    @logger
  end

end

