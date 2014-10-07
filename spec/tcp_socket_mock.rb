# coding: utf-8

##
# TCPSocket Mock which can be told what to send. Also received messages
# can be fetched. Fill the queue for messages to send with #send(msg).
# Get the oldest unread message received by calling #received.

class TCPSocketMock

  attr_reader :received

  def initialize(*args)
    @to_send = []
    @received = []
  end

  def send(msg)
    @to_send << msg
  end

  def gets
    @to_send.shift + "\r\n" if @to_send.any?
  end

  def print(msg)
    @received << msg.strip
  end
end


##
# Shared Example which can be included if a mocked, interceptable
# TCPSocket is needed. Provides "server" variable for adding messages
# to send and fetch received messages. Include before anyone calls the
# TCPSocket constructor in your example.

RSpec.shared_examples 'tcp_socket_mock' do
  let(:server) { TCPSocketMock.new }
  before { allow(TCPSocket).to receive(:new).and_return(server) }
end

