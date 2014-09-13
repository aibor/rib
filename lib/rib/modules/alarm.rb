# coding: utf-8

require 'time'
require 'alarms'

RIB::Module.new :alarm do
  desc 'Manage alarms'

  helpers do

    Alarms ||= AlarmBucket.new

    def list_alarms
      if Alarms.empty?
        "Currently no alarms active."
      else
        Alarms.map.with_index do |alarm,index|
          "#{index}: " +
            ((alarm.time.strftime('%D') == ::Time.new.strftime('%D')) ?
             "heute" : alarm.time.strftime('%v')) +
            " #{alarm.time.strftime('%T')} by #{alarm.user} - #{alarm.msg}"
        end.join(' --!!-- ')
      end
    end


    def delete_alarm(number)
      if !number[/\A[0-9]\z/] || !(alarm = Alarms[number])
        "No alarm found. Try again."
      elsif user != alarm.user
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
      elsif Alarms.add(date, message, user, source, &block)
        "added alarm, stay tuned!"
      else
        "dammit, something went wrong :\\"
      end
    end

  end


  command :alarm, :command, :num_or_time do
    desc 'Get, Set or Delete Alarms.' +
      ' Possible commands: list, del <[0-9]>, add <datetime> <msg>'
    on_call do
      resp = case command
             when 'list' then list_alarms
             when 'add' then  add_alarm(num_or_time, data.split[3..-1] * ' ')
             when 'del' then  delete_alarm(num_or_time)
             else "What? Try '#{bot.config.tc}help alarm'."
             end
      "#{user}: #{resp}"
    end

  end

end
