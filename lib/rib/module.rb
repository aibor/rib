# coding: utf-8

require 'rib'
require 'set'


##
# A bot framework needs to have a simple way to add functionality to
# it. The Module class is inteded to provide a simple way for writing
# Modules for the bot. It handles definition of Commands and Triggers,
# either for all protocols or only for specific ones.
#
# ## Commands
#
# Commands are all public instance methods defined in a subclass of
# {Module::Base}. Commands should have a short description which is
# used for help texts. Additional helper methods may be defined, but
# should be private.
# See {Module::Base} for available predefined helper methods.
#
# ## Triggers
#
# Triggers are very similar to Commands, but are not called by name.
# They are triggered, if a message matches their trigger regular
# expression. Definition is done by giving a regular expression and a
# block, which shall be called, wenn a message matches the regular
# expression. The MatchData object is passed to te block, so capture
# groups can be used in any way Ruby allows.
#
# @example HTML title fetching module
#   class LinkTitle < RIB::Module::Base
#
#     # describe the Module
#     describe 'Handle automatic HTML title fetching for URLs.'
#
#
#     # add a new config attribute and pass it a value
#     register title: true
#
#
#     # define a new command '!title' which takes one named argument
#     describe title: 'De-/Activate automatic HTML title fetching'
#
#     def title(on_off)
#       case on_off
#       when on
#         # use your added config attribute
#         bot.config.title = true
#         "HTML title fetching activated"
#       when off
#         bot.config.title = false
#         "HTML title fetching deactivated"
#       else
#         "#{user}, I don't understand you"
#       end
#     end
#
#
#     # define a new response for messages that contain an URL
#     response %r((http://\S+)) do |match|
#       # get the value of the regexp's MatchData with match
#       "Title: #{fetch_title(match[1])}"
#     end
#
#
#     # some stuff might only work with a particular protocol
#     protocol_only :irc do
#
#       desc formatting: 'A Command that only works in IRC, maybe due' +
#         ' to formatting special characters'
#
#       def formatting
#         # fancy stuff
#       end
#
#     end
#
#
#     private
#
#     # define some helper methods which can be used in on_call
#     # blocks
#     def fetch_title(url)
#       # code for fetching and parsing web pages for HTML titles
#     end
#
#   end
#
# @see Module::Base

class RIB::Module

  Directory = File.expand_path("../module/*.rb", __FILE__)


  class << self

    ##
    # If the module can only be used with specific protocols, these
    # can be set in this attribute. If it works with all protocols,
    # it is nil.
    #
    # @return [Array<Symbol>] if it works with several protocols
    # @return [nil]           if it works with all protocols

    attr_reader :protocols


    ##
    # Callback method, which is called when a class inherits from this
    # class. Used to add the sublass to our loaded module list.
    
    def inherited(subclass)
      loaded << subclass
      @init_blocks = []
      @descriptions = {}
      @timeouts = Hash.new(5)
      @triggers = {}
      super
    end


    ##
    # @return [Symbol] base class name of this class

    def key
      name.split(':').last.to_sym
    end


    ##
    # @return [Array<Proc>] blocks that should be called on init

    def init_blocks
      @init_blocks ||= []
    end


    ##
    # @return [Array<Symbol>] all available commands for this module

    def commands
      public_instance_methods(false)
    end


    ##
    # @return [Hash{Symbol => String}] descriptions for module and
    #   commands

    def descriptions
      @descriptions ||= {}
    end


    ##
    # @return [Hash{Symbol => Fixnum}] timeouts for commands

    def timeouts
      @timeout ||= Hash.new(5)
    end


    ##
    # @return [Hash{Regexp => Proc}] triggers and the blocks that should
    #   be called when they match

    def triggers
      @triggers ||= {}
    end


    ##
    # Check if this module responds to the command name and if this
    # method can take the number of arguments
    #
    # @param command_name [Symbol] name of the command
    # @param args_count   [Fixnum] number of arguments
    #
    # @return [Boolean]

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


    ##
    # Call the {.init_blocks} for this module.
    #
    # @param bot [Bot] the Bot instance the modules are used for.
    #
    # @return [void]

    def init(bot)
      init_blocks.each do |block|
        block.call(bot)
      end
    end


    ##
    # Load all modules in a directory.
    #
    # @param [String] path
    #
    # @return [Array<String>] found and loaded files

    def load_all(path = Directory)
      Dir[path].each { |f| load f }
      loaded
    end


    ##
    # Set that holds all subclasses of {Module::Base}, which are
    # Bot modules.
    #
    # @return [Set<Object>] either the Instances or just their base class
    #   names

    def loaded
      @loaded ||= ::Set.new
    end


    ##
    # Test if the instance is limited to specific protocols and if these
    # include one or several specific ones. This is useful for checking
    # if a {Module} is able to handle one or several protocols.
    #
    # @param protocol [Symbol]
    #
    # @return [Boolean] self is able to handle the passed protocol?

    def speaks?(protocol)
      case @protocols
      when Symbol then @protocols == protocol
      when Array  then @protocols.include?(protocol)
      when nil    then true
      else false
      end
    end


    private

    ##
    # Register a {Configuration] directive for the module.
    #
    # @param hash [Hash{Symbol => Object}]
    #
    # @return [void]

    def register(hash)
      raise TypeError, 'not a Hash' unless hash.is_a? Hash

      hash.each do |config_key, default_value|
        if config_key.respond_to?(:to_sym)
          RIB::Configuration.register(config_key.to_sym, default_value)
        end
      end
    end


    ##
    # Define a block that is called when {.init} is called for the
    # module by a Bot.
    #
    # @yieldparam bot [Bot]

    def on_init(&block)
      init_blocks << block if init_blocks.none?(&:source_location)
    end


    ##
    # If a String is passed, sets the description for the RIB::Module.
    # If a Hash is passed, it sets descriptions for the commands with
    # the name of the keys.
    #
    # @see #descriptions
    #
    # @param argument [String, Hash{Symbol => #to_s}]
    #
    # @return [void]

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


    ##
    # Set timeout for a command or a trigger. Default timeout is 5
    # seconds.
    #
    # @param hash [Hash{Symbol => Fixnum}]
    #
    # @return [void]

    def timeout(hash)
      raise TypeError, 'not a Hash' unless hash.is_a? Hash

      hash.each do |command, timeout|
        raise TypeError, 'not a Fixnum' unless timeout.is_a?(Fixnum)
        timeouts[command] = timeout
      end
    end


    ##
    # Define a block a bot should call if a message matches the
    # trigger. The block is evaluated in the instance scope of the
    # bot module it belongs to, which shall inherit from
    # {RIB::Module::Base}.
    #
    # @example
    #   trigger /\bcrap\b/ do
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

    def trigger(regexp, timeout = nil, &block)
      if regexp.is_a?(Regexp)
        triggers[regexp] = block
        timeouts[regexp] = timeout.to_i if timeout
      else
        raise TypeError, "not a Regexp: #{regexp.inspect}"
      end
    end

  end


  ##
  # The bot instance the module is called for.
  #
  # @return [Bot]

  attr_reader :bot


  ##
  # The message the module is called for.
  #
  # @return [Message]

  attr_reader :msg


  ##
  # @param bot [Bot]
  # @param msg [Message]

  def initialize(bot, msg)
    @bot, @msg = bot, msg
  end


  private

  ##
  # Logger that can be used for convenient logging from a module.
  #
  # @return [Logger]

  def logger
    unless @logger
      @logger = bot.logger.dup
      @logger.progname = self.class.name
    end
    @logger
  end

end

