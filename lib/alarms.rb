# coding: utf-8
#
require 'date'
require 'timeout'

class AlarmBucket
  attr_accessor :max

  Alarm = Struct.new(:time, :msg, :user, :source, :block)


  def initialize(max=10)
    @max = max
    @worker = nil
    @mutex = Mutex.new
  end


  def add(date = Time.now, message, user, source, &block)
    return false if full?
    @worker = worker
    @mutex.synchronize do
      @worker[:alarms] << Alarm.new(date, message, user, source, block)
    end
  end


  def full?
    self.to_a.size >= @max
  end


  def empty?
    self.to_a.empty?
  end


  def delete(id=nil)
    return false unless id = validate_id(id)
    self.to_a.delete_at(id)
  end


  def [](id=nil)
    return false unless id = validate_id(id)
    self.to_a[id]
  end


  def method_missing(meth, *args, &block)
    if Alarm.members.include? meth
      return false unless id = validate_id(args[0]) and alarm = self.to_a[id]
      alarm[meth]
    else
      super
    end
  end


  def map(&block)
    self.to_a.map &block
  end


  def to_a
    if @worker and @worker[:alarms]
      @worker[:alarms]
    else
      []
    end
  end


  private

  def worker
    return @worker if @worker and @worker.alive?
    new_thread = Thread.new do
      @mutex.synchronize do
        Thread.current[:alarms] ||= Array.new
      end
      worker_run!
    end
    sleep 0.1

    return new_thread
  end


  def worker_run!
    loop do
      sleep 1
      @mutex.synchronize do
        call_alarms_due Thread.current[:alarms]
      end
      break if Thread.current[:alarms].empty?
    end
  end


  def run_alarm_task alarm
    Thread.new do
      Timeout::timeout 5 do
        alarm.block.call Struct.new(*Alarm.members.take(4)).new(*alarm.take(4))
      end
    end
  end


  def call_alarms_due alarms
    alarms.compact.each_with_index do |alarm,index|
      if alarm.time <= Time.now
        run_alarm_task alarm
        Thread.current[:alarms].delete_at(index)
      end
    end
  end


  def validate_id(id=nil)
    (id.nil? or ! id.respond_to? "to_i") ? false : id.to_i
  end


end
