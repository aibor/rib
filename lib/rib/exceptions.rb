# coding: utf-8

module RIB::Exceptions

  class Error < ::StandardError; end

  ##
  # Raised if an duplicate object is requested to be added to a list.

  class DuplicateError < Error

    def initialize(name); @name = name end

    def message; "The name '#{@name}' is not unique" end

  end


  ##
  # Raised if an attribute is requested to be added to an
  # {Configuration} instance, which has the same name as an already
  # present attribute.

  class AttributeExistsError < DuplicateError

    def message
      "An attribute with the name '#{@name}' already exists."
    end

  end


  ##
  # Raised if an method name is protected and can't be used for
  # dynamically created methods.

  class ReservedNameError < DuplicateError

    def message
      "Methodname is reserved: '#{@name}'"
    end

  end


  ##
  # Raised if connection to the server is lost.

  class LostConnectionError < Error

    def message
      "Lost connection. Reconnecting in 2 seconds."
    end

  end


  ##
  # Raised if a child didn't overwrite an essential method.

  class NotImplementedError < Error

    ##
    # @param name [Symbol] method name

    def initialize(name); @name = name; end

    def message
      "Method ##{@name}' not implemented by child."
    end

  end


  class NotInstantiatableError < Error

    def message
      "Tried to instantiate an abstract class."
    end

  end


  ##
  # Raised if an Error is received during login.

  class LoginError < Error; end


  ##
  # Raised if Authentication fails.

  class AuthError < Error; end


  ##
  # Raised if a channel couldn't be joined.

  class ChannelJoinError < Error; end


  ##
  # Raised if a malformed message is received.

  class MalformedMessageError < Error; end


  ##
  # Raised if an Error is received from the server.

  class ReceivedError < Error; end


  ##
  # Raised if an invalid comamnd is called or a known command is called
  # improperly.

  class CommandError < Error; end

end

