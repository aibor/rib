# coding: utf-8
#
require 'date'

class AlarmBucket
  attr_accessor :max

  THREAD_VARS = [ :date, :user, :source, :date ].freeze

  def initialize(max=10)
    @alarms = Array.new
    @max = max
  end

  def add(date = Time.now, message, user, source)
    return false if full?
    @alarms << Thread.new do
      Thread.current[:date] = date
      Thread.current[:msg] = message
      Thread.current[:user] = user
      Thread.current[:source] = source

      while Thread.current[:date] > Time.now do
        sleep 1
      end

      yield(Thread.current)

      @alarms.delete_if {|a| a == Thread.current}
    end
  end

  def full?
    @alarms.size >= @max
  end

  def empty?
    @alarms.empty?
  end

  def delete(id=nil)
    return false unless id = validate_id!(id)
    @alarms.delete_at(id).kill
  end

  def [](id=nil)
    return false unless id = validate_id!(id)
    @alarms[id]
  end

  def method_missing(meth, *args, &block)
    if THREAD_VARS.include? meth
      return false unless id = validate_id!(args[0]) and @alarms[id]
      @alarms[id][meth]
    else
      super
    end
  end

  def map(&block)
    @alarms.map &block 
  end

  private

  def validate_id!(id=nil)
    (id.nil? or ! id.respond_to? "to_i") ? false : id.to_i
  end
end


