# coding: utf-8

require 'rib'


##
# Store for `num` last messages received. Most recent message first.

class RIB::Backlog

  include Enumerable


  ##
  # Number of messages to store.
  #
  # @return [Integer]

  attr_accessor :num


  ##
  # @param num [Integer]

  def initialize(num = 1000)
    @num      = num
    @backlog  = Array.new
    @mutex    = Mutex.new
    @current = nil
  end


  ##
  # Add a message to the backlog.
  #
  # @param msg [RIB::Message]

  def add(msg)
    if msg.is_a?(RIB::Message)
      add_to_backlog(msg)
    else
      raise TypeError, "not a RIB::Message: '#{msg.class}'" 
    end
  end

  alias :push :add
  alias :<<   :add


  ##
  # Iterate through backlog and yield the block for each message.
  #
  # @yieldparam message [RIB::Message]
  # @yieldreturn [void]
  #
  # @return [self]

  def each(&block)
    @backlog.each(&block)
  end


  ##
  # @return [Integer] currently stored messages
  def size
    @backlog.size
  end

  alias :count :size


  private

  ##
  # @param msg [RIB::Messages]
  # 
  # @return [void]

  def add_to_backlog(msg)
    @mutex.synchronize do
      if @current
        @backlog.pop while size >= @num
        @backlog.unshift(@current)
      end
      @current = msg
    end
  end

end

