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

      ##
      # @param [Hash] hash  values which will be available to executed
      #   blocks by {#exec}

      def initialize(hash = {})
        @hash = hash
        @params = hash[:params] || {}
      end


      ##
      # Run a block in our clean Handler environment and return its return
      # value.
      #
      # @param [Proc] action block to call in the instances namespace
      #
      # @return[Object] return value of the block

      def exec(&action)
        instance_eval &action
      end


      ##
      # Make values in our hash instance variable available. Since command
      # params should be easily accessible, the params instance_variable is
      # looked up separately.
      #
      # @raise [NoMethodError] if the called method couldn't be found in the
      #   hash or in the params

      def method_missing(meth, *args)
        if @hash[meth]
          @hash[meth]
        elsif @params.has_key?(meth)
          @params[meth]
        else
          ::Kernel.raise(::NoMethodError,
                         "method '#{meth}' not available in Commands")
        end
      end

    end

  end

end

