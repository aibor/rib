# coding: utf-8


RIB::Module.new :core do

  desc 'Core Module'


  command :quit do
    desc = 'Quits the connection'
    on_call do |msg, params, bot|
      if msg.user == bot.admin and Time.now - bot.starttime > 5
        bot.connection.quit(bot.qmsg)
      end
    end
  end


  protocol_only :irc do

    command :join, :channel do
      desc 'Join a new channel'
      on_call do |msg, params, bot|
        puts msg.user
        bot.connection.join_channel(params[:channel]) if msg.user == bot.admin
      end
    end


    command :part, :channel do
      desc 'Leave a channel'
      on_call do |msg, params, bot|
        channel = params[:channel]
        channel ||= msg.source
        bot.connection.part(channel) if msg.user == bot.admin
      end
    end

  end


  command :uptime do
    desc 'Print bot uptime'
    on_call do |msg, params, bot|
      diff = (Time.now - bot.starttime).to_i

      time =  [diff/(3600*24)]
      time << diff.modulo(3600*24)/3600
      time << diff.modulo(3600)/60
      time << diff.modulo(60)

      case bot.protocol
      when :irc
        "Uptime: #{'%3dd %02d:%02d:%02d' % time}   " +
        "Started: #{bot.starttime.strftime("%d.%m.%Y %T %Z")}"
      when :xmpp
        "Uptime: #{'%3dd %02d:%02d:%02d' % time}   " +
        "Started: #{bot.starttime.strftime("%d.%m.%Y %T %Z")}"
      end
    end
  end


  command :list, :modul do
    desc = 'List all available Modules or commands for a specific Module'
    on_call do |msg, params, bot|
      modul = params[:modul]
      if modul
        mod = bot.modules.find do |m|
          m.name.to_s.downcase == modul.downcase
        end

        if mod
          'Module commands: ' + mod.commands.map(&:name) * ', '
        else
          'Unknown module'
        end
      else
        'Available Modules: ' + bot.modules.map{|m| m.name.to_s.capitalize}.join(', ')
      end
    end
  end


  command :reload do
    desc = 'Reload all Modules'
    on_call do |msg, dummy, bot|
      bot.reload_modules
      'done'
    end
  end

end
