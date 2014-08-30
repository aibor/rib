# coding: utf-8

module RIB

  class UnknownProtocol < StandardError

    def initialize(protocol_name)
      @protocol_name = protocol_name
    end
    

    def message
      "can 't handle protocol '#{@protocol_name}'"
    end

  end


  class DuplicateModuleError < StandardError

    def initialize(name)
      @name = name
    end


    def message
      "A Module with the name '#{@name}' has already been loaded."
    end

  end


  class LoginError       < StandardError; end

  class AuthError        < StandardError; end

  class ChannelJoinError < StandardError; end

end
