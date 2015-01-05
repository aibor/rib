#!/usr/local/bin/ruby -w

#$server_responses = Array.new
#$client_output    = String.new

TCPSocketMock = Minitest::Mock.new

class TCPSocket

  def self.new(*args)
    return TCPSocketMock
  end

end

