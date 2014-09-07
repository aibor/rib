# coding: utf-8

module RIB

  module Exceptions

    class UnknownProtocol < StandardError

      def initialize(protocol_name)
        @protocol_name = protocol_name
      end


      def message
        "can 't handle protocol '#{@protocol_name}'"
      end

    end


    class DuplicateError < StandardError

      def initialize(name)
        @name = name
      end


      def message
        "The name '#{name}' is not unique"
      end

    end


    class DuplicateModuleError < DuplicateError

      def message
        "A Module with the name '#{@name}' has already been loaded."
      end

    end


    class DuplicateCommandError < DuplicateError

      def message
        "A Command with the name '#{@name}' has already been loaded."
      end

    end


    class LoginError            < StandardError; end
    class AuthError             < StandardError; end
    class ChannelJoinError      < StandardError; end
    class MalformedMessageError < StandardError; end
    class ReceivedError         < StandardError; end

  end

end
