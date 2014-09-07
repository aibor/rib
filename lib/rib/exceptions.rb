# coding: utf-8

module RIB

  module Exceptions

    ##
    # Raised if an unknown protocol is requested.

    class UnknownProtocolError < StandardError

      ##
      # @param [#to_s] protocol_name name of the unknown protocol

      def initialize(protocol_name)
        @protocol_name = protocol_name
      end


      ##
      # @return [String] default message

      def message
        "can 't handle protocol '#{@protocol_name}'"
      end

    end


    ##
    # Raised if a requested protocol isn't in Objects protocol list.

    class ProtocolMismatchError < StandardError

      ##
      # @return [String] default message

      def message
        'Protocol definitions incompatible'
      end

    end


    ##
    # Raised if an duplicate object is requested to be added to a list.

    class DuplicateError < StandardError

      ##
      # @param [#to_s] name name of the duplicate

      def initialize(name)
        @name = name
      end


      ##
      # @return [String] default message

      def message
        "The name '#{name}' is not unique"
      end

    end


    ##
    # Raised if a {Module} is requested to be added to the list of
    # loaded Modules, which has the same name as an already loaded
    # {Module}.

    class DuplicateModuleError < DuplicateError

      ##
      # @return [String] default message

      def message
        "A Module with the name '#{@name}' has already been loaded."
      end

    end


    ##
    # Raised if a {Command} is requested to be added to the command list
    # of a {Module}, which has the same name as an already loaded
    # {Command}.

    class DuplicateCommandError < DuplicateError

      ##
      # @return [String] default message

      def message
        "A Command with the name '#{@name}' has already been added."
      end

    end


    ##
    # Raised if a {Response} is requested to be added to the response
    # list of a {Module}, which has the same name as an already loaded
    # {Response}.

    class DuplicateResponseError < DuplicateError

      ##
      # @return [String] default message

      def message
        "A Response with the name '#{@name}' has already been added."
      end

    end


    ##
    # Raised if an attribute is requested to be added to an
    # {Configuration} instance, which has the same name as an already
    # present attribute.

    class AttributeExistsError < DuplicateError

      ##
      # @return [String] default message

      def message
        "An attribute with the name '#{name}' already exists."
      end

    end
                                       

    ##
    # Raised if an Error is received during login.

    class LoginError            < StandardError; end
                                       

    ##
    # Raised if Authentication fails.

    class AuthError             < StandardError; end
                                       

    ##
    # Raised if a channel couldn't be joined.

    class ChannelJoinError      < StandardError; end
                                       

    ##
    # Raised if a malformed message is received.

    class MalformedMessageError < StandardError; end
                                       

    ##
    # Raised if an Error is received from the server.

    class ReceivedError         < StandardError; end

  end

end
