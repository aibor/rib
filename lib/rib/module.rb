# coding: utf-8

require 'rib/command'
require 'rib/response'
require 'rib/helpers'

module RIB

  class Module

    include Helpers
    extend  Helpers


    class << self

      ##
      # All loaded Modules.
      #
      # @return [Array<Module>]

      attr_reader :loaded


      ##
      # Load a file or  directory. If they contain RIB::Modules, they are
      # instantiated and added to the 'loaded' attribute.
      #
      # @param [String] path
      #
      # @return [void]

      def load_path(path)
        @loaded = []

        Dir.glob(path).each {|f| load f}
      end


      ##
      # Add a module to the 'loaded' attribute. If it already has a Module with
      # that name, an exception is raised.
      #
      # @param [Module] mod
      #
      # @raise [DuplicateModuleError] if there already is a Module with that
      #   name
      #
      # @return [void]

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
    # Name of the Module. Must be unique.
    #
    # @return [Symbol]

    attr_reader :name


    ##
    # Short description of the purpose of this module.
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
    # All commands this module provides.
    #
    # @return [Array<Command>]

    attr_reader :commands

    
    ##
    # All responses this module provides.
    #
    # @return [Array<Response>]

    attr_reader :responses


    ##
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

    def initialize(name, &block)
      @name       = name.to_sym.downcase
      @commands   = []
      @responses  = []

      instance_eval &block if self.class.add_to_loaded_modules self

      @commands.freeze
      @responses.freeze
    end


    private

    ##
    # Set description for this module
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


    ##
    # Define a command a bot should respond to. The name and the optional
    # parameter names are passed as attributes. Further attributes are set
    # in the mandatory block. This block is evaluated in the instance namespace
    # of the freshly created {Command} object.
    #
    # @see Action#desc
    # @see Action#on_call
    #
    # @example
    #   command :tell, :who, :what do
    #     desc 'Tell somebody something'
    #     on_call do
    #       "#{who}: #{what}"
    #     end
    #   end
    #
    # @param [#to_sym] name   name of the command
    # @param [Array<#to_sym>] params  name of none or several params
    #   for this command
    # @param [Proc] block  block to call on instantiation of Command           
    #
    # @raise [TypeError] if name is not a Symbol
    # @raise [DuplicateCommandError] if name is not unique for this Module
    #
    # @return [Command]

    def command(name, *params, &block)
      raise TypeError, 'not a Symbol' unless name.is_a? Symbol
      raise DuplicateCommandError if @commands.find { |c| c.name == name }

      cmd = Command.new name, @name, params, @protocol, &block
      @commands << cmd
      cmd
    end


    ##
    # @return [Response]

    def response(name, trigger, &block)
      raise TypeError, 'not a Symbol' unless name.is_a? Symbol
      raise TypeError, 'not a Regexp' unless trigger.is_a? Regexp

      resp = Response.new name, @name, trigger, @protocol, &block
      @responses << resp
      resp
    end


    ##
    # @return [void]

    def helpers(&block)
      Action::Handler.class_eval &block
    end


    ##
    # Limit the availability for a commands to one or mor protocols.
    # This only works, if the Module itself isn't limited to one
    # specific protocol.
    #
    # @param [Symbol, Array<Symbol>] protocol
    #
    # @return [void]

    def protocol_only(protocol)
      ensure_symbol_or_array_of_symbols protocol

      before = @protocol
      @protocol ||= protocol

      if block_given?
        yield
        @protocol = before
      end
    end

  end
end
