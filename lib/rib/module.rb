# coding: utf-8

require 'rib/command'

module RIB

  class Module

    class << self

      attr_reader :loaded


      def load(path)
        @loaded = []

        Dir.glob(path).each {|f| load f}
      end


      def add_to_loaded_modules(mod)
        @loaded ||= []

        if @loaded.bsearch {|m| m.name == mod.name}
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

    attr_reader :desc


    ##
    # If the module can only be used with specific protocols, these 
    # can are set in this attribute. Otherwise it is nil.
    #
    # @return [Symbol, Array<Symbol>, nil]

    attr_reader :protocol
    
    
    ##
    # All commands this module provides.
    #
    # @return [Array<Command>]

    attr_reader :commands


    def initialize(name, &block)
      @name     = name
      @commands = []

      instance_eval &block if self.class.add_to_loaded_modules self
    end


    def speaks?(protocol)
      raise TypeError, 'not a Symbol' unless protocol.is_a? Symbol

      case self.protocol
      when nil then true
      when Symbol then self.protocol == protocol
      when Array then self.protocol.include? protocol
      else false
      end
    end


    private

    def desc(description)
      if description.is_a? String
        @description = description
      else
        raise TypeError, 'not a String'
      end
    end


    def command(name, *params, &block)
      cmd = Command.new name, @name, params, @protocol, &block
      self.commands << cmd
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


    ##
    # @param [Object] object  an object to check
    #
    # @return [TrueClass]
    #
    # @raise [TypeError] if object isn't a Symbol or Array of Symbols

    def ensure_symbol_or_array_of_symbols(object)
      case object
      when Symbol then true
      when Array then object.all? {|e| e.is_a? Symbol}
      else raise TypeError, 'not a Symbol or Array of Symbols'
      end
    end

  end
end
