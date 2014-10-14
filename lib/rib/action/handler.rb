# coding: utf-8

module RIB

  class Action

    ##
    # In order to run the iaction blocks in an environment as clean as
    # possible, they are called from within a class, which inherited
    # from BasicObject.
    # So the only additonal methods available are the one handled by
    # {#method_missing}, which allows access to the values of the Hash
    # passed on instantiation.

    class Handler < BasicObject

      attr_accessor :invocation_hash

      def initialize
        @invocation_hash = nil
      end


      ##
      # Make values in our hash instance variable available. Since command
      # params should be easily accessible, the params instance_variable is
      # looked up separately.
      #
      # @raise [NoMethodError] if the called method couldn't be found in the
      #   hash or in the params

      def method_missing(meth, *args)
        if @invocation_hash && @invocation_hash[meth]
          @invocation_hash[meth]
        else
          ::Kernel.raise(::NoMethodError,
                         "method '#{meth}' not available")
        end
      end

    end

  end

end

