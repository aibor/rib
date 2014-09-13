# coding: utf-8

require 'rib/command'
require 'rib/response'
require 'rib/helpers'

module RIB

  ##
  # A bot framework needs to have a simple way to add functionality to
  # it. The Module class is inteded to provide a DSL for writing
  # Modules for the bot. It handles definition of Commands, Responses
  # and Helpers, either for all protocols or only for specific ones.
  #
  # ## Commands
  #
  # Commands are called by name with optional parameters, which can have
  # names defined. Commands should have a short description which is
  # used for help texts. They need to have a block that is called on
  # invocation, otherwise there would be no point for a Command.
  # See {Command#call} for available methods in {Action#on_call
  # Command#on_call} blocks.
  #
  # ## Responses
  #
  # Responses are very similar to Commands, but are not called by name.
  # They are triggered, if a message matches their trigger regular
  # expression. Definition is almost the same as for Commands, but take
  # a trigger regular expression instead of parameters. See below for
  # an example.
  # See {Response#call} for available methods in {Action#on_call 
  # Response#on_call} blocks.
  #
  # @example HTML title fetching module
  #   RIB::Module.new :title do
  #     desc 'Handle automatic HTML title fetching for received URLs.'
  #
  #     # add a new config attribute and pass it a value
  #     on_load do |bot|
  #       bot.config.register(:title, true)
  #     end
  #
  #     # define some helper methods which can be used in on_call
  #     # blocks
  #     helpers do
  #       def fetch_title(url)
  #         # code for fetching and parsing web pages for HTML titles
  #       end
  #     end
  #
  #     # define a new command '!title' which takes one named argument
  #     command :title, :on_off do
  #       desc 'De-/Activate automatic HTML title fetching'
  #       # what will be done when the command is called?
  #       on_call do
  #         # call the argument by its name
  #         case on_off
  #         when on
  #           # use your added config attribute
  #           bot.config.title = true
  #           "HTML title fetching activated"
  #         when off
  #           bot.config.title = false
  #           "HTML title fetching deactivated"
  #         else
  #           "#{user}, I don't understand you"
  #         end
  #       end
  #     end
  #
  #     # define a new response for messages that contain an URL
  #     response :title, %r((http://\S+)) do
  #       desc 'automatically fetch and send the HTML title'
  #       on_call do
  #         # get the value of the regexp's MatchData with match
  #         "Title: #{fetch_title(match[1])}"
  #       end
  #     end
  #
  #     # some stuff might only work with a particular protocol
  #     protocol_only :irc do
  #
  #       command :formating do
  #         desc 'A Command that only works in IRC, maybe due to' +
  #           ' formatting special characters'
  #         on_call do
  #           # fancy stuff
  #         end
  #       end
  #
  #     end
  #
  #   end
  #
  # @see Action
  # @see Command
  # @see Response

  class Module

    include Helpers
    extend  Helpers


    class << self

      ##
      # All Modules that have been loaded and can be used by {Bot}.
      #
      # @return [Array<Module>]

      attr_reader :loaded


      ##
      # Load a file or  directory. If they contain RIB::Modules, they are
      # instantiated and added to the 'loaded' attribute.
      #
      # @param [String] path
      #
      # @return [Array<String>] found and loaded files

      def load_path(path)
        @loaded = []

        abs = File.expand_path(__FILE__ + '/..') + "/#{path}"
        Dir.glob(abs).each {|f| load f if File.file?(f)}
      end


      ##
      # Add a module to the 'loaded' attribute. If it already has a
      # Module with that name, an exception is raised.
      #
      # @param [Module] mod
      #
      # @raise [DuplicateModuleError] if there already is a Module with
      #   that name
      #
      # @return [Array<Module>] current value of lodaded attribute

      def add_to_loaded_modules(mod)
        @loaded ||= []

        if array_has_value?(@loaded, :name, mod.name)
          raise DuplicateModuleError
        else
          @loaded << mod
        end
      end

    end


    ##
    # Name of the Module. Must be unique. Otherwise an exception will
    # be raised when tryiung to add it to the loaded attribute.
    #
    # @return [Symbol]

    attr_reader :name


    ##
    # Short description of the purpose of this module. Will be used in
    # help texts.
    #
    # @return [String]

    attr_reader :description


    ##
    # If the module can only be used with specific protocols, these
    # can be set in this attribute. If it works with all protocols,
    # it is nil.
    #
    # @return [Symbol]        if it works with one protocol
    # @return [Array<Symbol>] if it works with several protocols
    # @return [nil]           if it works with all protocols

    attr_reader :protocol


    ##
    # All commands this module provides. Names of the Commands are
    # unique within a module. If a {Command} is tried to be added with a
    # name that an already added {Command} has, an exception is raised.
    #
    # @return [Array<Command>] all currently known Commands

    attr_reader :commands


    ##
    # All responses this module provides. Names of the Responses are
    # unique within a module. If a {Response} is tried to be added with
    # a name that an already added {Response} has, an exception is
    # raised.
    #
    # @return [Array<Response>] all currently known Responses.

    attr_reader :responses


    ##
    # New Modules need to be instantiated with a name and a block.
    # The block is evaluated in the instance namespace of the new
    # Module object.
    #
    # @example
    #   RIB::Module.new :my_module do
    #     desc 'so awesome'
    #
    #     command :moo do
    #       desc "I'm a cow, lol"
    #       on_call do
    #         'Mooo0000oooo'
    #       end
    #     end
    #   end
    #
    # @param [#to_sym] name  the module name
    # @param [Proc] block  definition of available commands, responses
    #   and helpers

    def initialize(name, &block)
      @name       = name.to_sym.downcase
      @commands   = []
      @responses  = []

      instance_eval &block if self.class.add_to_loaded_modules self

      @commands.freeze
      @responses.freeze
    end


    ##
    # Calls the block set by {#on_load}. Should be called by a {Bot}
    # instance passing itself as argument.
    #
    # @param [Bot] bot

    def init(bot)
      raise TypeError, 'not a Bot' unless bot.is_a? Bot
      @on_load.call(bot) if @on_load
    end


    private

    ##
    # Set a description for this module
    #
    # @param [#to_s] description
    #
    # @return [String] the description that has been set

    def desc(description)
      if description.respond_to? :to_s
        @description = description.to_s
      else
        raise TypeError, "doesn't respond to #to_s"
      end
    end


    ##
    # Pass a block that will be invoked when the Module is loaded by a
    # {Bot} instance. It is intended to {Configuration#register register
    # new Configuration attributes} which can be dynamically changed
    # in runtime by {Command Commands}.
    #
    # @yieldparam [Bot] bot {Bot} instance the module is loaded by
    # @yieldreturn [void]
    #
    # @return [Proc]

    def on_load(&block)
      @on_load = block 
    end


    ##
    # Define a command a bot should respond to. The name and the
    # optional parameter names are passed as attributes. Further
    # attributes are set in the mandatory block. This block is evaluated
    # in the instance namespace of the new {Command} object. The on_call
    # block will be evluated in an {Action::Handler} instance namespace
    # and therefor has a very limited method list.
    #
    # @see Command#call for available methods in the on_call block
    #
    # @example
    #   command :tell, :who, :what do
    #     desc 'Tell somebody something'
    #     on_call do
    #       "#{who}: #{what}"
    #     end
    #   end
    #
    # @param [#to_sym]        name    name of the {Command}
    # @param [Array<#to_sym>] params  name of none or several params
    #                                 for this {Command}
    #
    # @yield (see Action#on_call)
    # @yieldreturn (see Action#on_call)
    #
    # @raise [TypeError] if name is not a Symbol
    # @raise [DuplicateCommandError] if name is not unique for this
    #                                Module
    #
    # @return [Command] the created and added {Command}

    def command(name, *params, &block)
      raise TypeError, 'not a Symbol' unless name.is_a? Symbol

      if array_has_value?(@commands, :name, name)
        raise DuplicateCommandError
      end

      cmd = Command.new name, @name, params, @protocol, &block
      @commands << cmd
      cmd
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

    def response(name, trigger, &block)
      raise TypeError, 'not a Symbol' unless name.is_a? Symbol
      raise TypeError, 'not a Regexp' unless trigger.is_a? Regexp

      if array_has_value?(@responses, :name, name)
        raise DuplicateResponseError
      end

      resp = Response.new name, @name, trigger, @protocol, &block
      @responses << resp
      resp
    end


    ##
    # Add some Code like constants and method definition to the
    # {Action::Handler} namespace. This will be available for all
    # Modules' Commands and Responses.
    #
    # @yield  block to call on in the {Action::Handler} namespace
    #
    # @return [void]

    def helpers(&block)
      Action::Handler.class_eval &block
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
    # @param [Symbol, Array<Symbol>] protocol
    #
    # @yield limits the definitions within the block to protocol instead
    #   of the whole Module
    #
    # @raise [ProtocolMismatch] if the Module protocols doesn't contain
    #   one or more of the protocols passed
    #
    # @return [void]

    def protocol_only(protocol)
      ensure_symbol_or_array_of_symbols protocol

      raise ProtocolMismatchError unless speaks?(protocol)

      before = @protocol
      @protocol = protocol

      if block_given?
        yield
        @protocol = before
      end
    end

  end
end
