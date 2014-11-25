# coding: utf-8

require 'time'
require 'alarm_bucket'
require 'rib/module'


class RIB::Module::Alarm < RIB::Module

  describe 'Manage alarms'


  Alarms ||= AlarmBucket.new
    

  describe alarm: <<-EOS
    'Get, Set or Delete Alarms. Possible commands:
    list, del <[0-9]>, add <datetime> <msg>'
  EOS

  def alarm(subcommand, *args)
    missing_args_msg = "No arguments given."
    first = args.shift
    resp = case subcommand
           when 'list' then list_alarms
           when 'add' 
             args.any? ? add_alarm(first, args * ' ') : missing_args_msg
           when 'del'
             args.any? ? delete_alarm(first) : missing_args_msg
           end

    "#{msg.user}: #{resp}"
  end


  private

  def list_alarms
    if Alarms.empty?
      "Currently no alarms active."
    else
      Alarms.map.with_index do |alarm,index|
        out = "#{index}: "
        out += if alarm.time.to_date == Date.today then "today"
               else alarm.time.strftime('%v') end
        out += " #{alarm.time.strftime('%T')}"
        out += " by #{alarm.user} - #{alarm.msg}"
        out
      end.join(' --!!-- ')
    end
  end


  def delete_alarm(number)
    if !number[/\A[0-9]\z/] || !(alarm = Alarms[number])
      "No alarm found. Try again."
    elsif msg.user != alarm.user
      "dafuq? Who the hell are you? oO"
    else
      if Alarms.delete(param)
        "alarm deleted"
      else
        "ouch, something went wrong :/"
      end
    end
  end


  def add_alarm(time, message)
    date = ::Time.parse(time)
    block = ::Proc.new do |alarm|
      bot.say("ALARM by #{alarm.user}: " + alarm.msg, alarm.source)
    end

    if date <= ::Time.now
      "This date is in the past! Try again."
    elsif Alarms.full?
      "Sorry, I already have 10 alarms to handle."
    elsif Alarms.add(date, message, msg.user, msg.source, &block)
      "added alarm, stay tuned!"
    else
      "dammit, something went wrong :\\"
    end
  end

end

