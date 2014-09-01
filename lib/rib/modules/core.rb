# coding: utf-8


RIB::Module.new :core do

  desc 'Core Module'


  command :quit do
    desc = 'Quits the connection'
    on_call do |msg|
      if msg.user == bot.admin and Time.now - bot.starttime > 5
        bot.connection.quit(bot.qmsg)
      end
    end
  end


  protocol :irc do
    command :join, :channel do
      desc 'Join a new channel'
      on_call do |msg|
        bot.connection.join(msg.params[:channel]) if msg.user == bot.admin
      end
    end



    command :part, :channel do
      desc 'Leave a channel'
      on_call do |msg|
        bot.connection.part(msg.params[:channel]) if msg.user == bot.admin
      end
    end
  end


  command :uptime do
    desc 'Print bot uptime'
    on_call do
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


  command :list, :module do
    desc = 'List all available Modules or commands for a specific Module'
    on_call do |msg|
      if msg.params[:module]
        mod = bot.modules.select do |m|
          m.name.downcase == msg.params[:module].downcase
        end.first
        mod ? 'Module commands: ' + mod.commands.map(&:name).join(', ') : 'Unknown module'
      else
        'Available Modules: ' + bot.modules.map{|m| m.name.capitalize}.join(', ')
      end
    end
  end


  command :reload do
    desc = 'Reload all Modules'
    on_call do
      bot.reload_modules
      'done'
    end
  end

end
