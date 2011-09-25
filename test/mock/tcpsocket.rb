#!/usr/local/bin/ruby -w

$server_responses = Array.new
$client_output    = String.new

class MockTCPSocket
  def initialize( host, port )
    # we don't need +host+ or +port+--just keeping the interface
  end

  def gets
    if $server_responses.empty?
      raise "The server is out of responses."
    else
      $server_responses.shift + "\r\n"
    end
  end

  def print( line )
    $client_output << line
  end
end
