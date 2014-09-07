# coding: utf-8

module RIB

  module Helpers

    ##
    # Test if the instance is limited to specific protocols and if these
    # include one or several specific ones. This is useful for checking
    # if a {Module}, {Command} or {Response} are able to handle one
    # or several protocols.
    #
    # @param [Symbol, Array<Symbol>] protocols  one or several protocol
    #   names to check
    #
    # @raise [TypeError] if protocols isn't a Symbol or Array of Symbols
    # @raise [NoMethodError] if self doesn't respond to #protocol
    #
    # @return [Boolean] self is able to handle all of the passed
    #   protocols?

    def speaks?(protocols)
      ensure_symbol_or_array_of_symbols protocols

      case self.protocol
      when nil
        true
      when Symbol
        case protocols
        when Symbol then self.protocol == protocols
        when Array  then protocols.include? self.protocol
        end
      when Array
        case protocols
        when Symbol then self.protocol.include? protocol
        when Array  then (protocols - self.protocol).empty?
        end
      else false
      end
    end


    ##
    # Check if an Array with elements, which respond to a specific method,
    # already has an element with a specific value.
    #
    # @param [Array] array    Array with elements which respond to method
    # @param [Symbol] method  method to call on the elements
    # @param [Object] value   value to check the metod's return value against
    #
    # @raise [TypeError] if array is not an Array
    # @raise [TypeError] if method is not a Symbol
    #
    # @return [Boolean] Array includes an element with this value?

    def array_has_value?(array, method, value)
      raise TypeError, 'not an Array' unless array.is_a? Array
      raise TypeError, 'not a Symbol' unless method.is_a? Symbol

      array.any? do |element|
        element.respond_to? method
        element.send(method) == value
      end
    end


    ##
    # @param [Object] object  an object to check
    #
    # @return [TrueClass] object passed the check
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
