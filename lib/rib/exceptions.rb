# coding: utf-8

require 'rib'


module RIB::Exceptions

  ##
  # Raised if an duplicate object is requested to be added to a list.

  class DuplicateError < StandardError

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

  class LostConnectionError < StandardError

    def message
      "Lost connection. Reconnecting in 2 seconds."
    end

  end


  ##
  # Raised if an Error is received during login.

  class LoginError < StandardError; end


  ##
  # Raised if Authentication fails.

  class AuthError < StandardError; end


  ##
  # Raised if a channel couldn't be joined.

  class ChannelJoinError < StandardError; end


  ##
  # Raised if a malformed message is received.

  class MalformedMessageError < StandardError; end


  ##
  # Raised if an Error is received from the server.

  class ReceivedError < StandardError; end

end

