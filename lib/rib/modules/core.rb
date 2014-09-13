# coding: utf-8


RIB::Module.new :core do

  desc 'Core Module'


  command :quit do
    desc 'Quits the connection'
    on_call do
      if user == bot.config.admin and Time.now - bot.starttime > 5
        bot.connection.quit(bot.config.qmsg)
      end
    end
  end


  protocol_only :irc do

    command :join, :channel do
      desc 'Join a new channel'
      on_call do
        if user == bot.config.admin
          bot.connection.join_channel(params[:channel])
        end
      end
    end


    command :part, :channel do
      desc 'Leave a channel'
      on_call do
        channel = params[:channel]
        channel ||= msg.source
        bot.connection.part(channel) if user == bot.config.admin
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

      case bot.config.protocol
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
    desc 'List all available Modules or Commands for a specific Module'
    on_call do
      if self.module
        mod = bot.modules.find do |m|
          m.name.to_s.downcase == self.module.downcase
        end

        if mod
          'Module commands: ' + mod.commands.map(&:name) * ', '
        else
          'Unknown module'
        end
      else
        modules = bot.modules.map do |m|
          m.name.to_s.split('_').map(&:capitalize).join
        end
        "Available Modules: #{modules * ', '}"
      end
    end
  end


  helpers do

    def print_help(cmd)
      params_string = cmd.params.map { |p| " <#{p.capitalize}>" }.join

      "Module: #{cmd.module.capitalize}, Usage: #{bot.config.tc}#{cmd.name}" +
      "#{params_string} --- #{cmd.description}"
    end

  end


  command :help, :command do
    desc 'Print short help text for a command'
    on_call do
      if command
        if cmd = bot.commands.find { |c| c.name.to_s == command }
          print_help cmd
        else
          "Unknown command '#{command}'. Try '#{bot.config.tc}list'."
        end
      else
        print_help bot.commands.find { |c| c.name == :help }
      end
    end
  end


  command :reload, :what do
    desc 'Reload all Modules'
    on_call do
      if user = bot.config.admin
        case what
        when 'modules' then bot.reload_modules ? 'done' : 'Me failed q.q'
        when 'replies' then bot.reload_replies ? 'done' : 'Me failed q.q'
        else 'dunno'
        end
      else
        ['How about no?', 'Go away!', '°.°', '<_<', 'sryly?'].sample
      end
    end
  end


  helpers do

    def add_reply(trigger, value = nil)
      if value && bot.add_reply(trigger, value * ' ')
        'Added this crap!'
      else
        'Me or you failed :/'
      end
    end


    def delete_reply(trigger, id = nil)
      if id && bot.delete_reply(trigger, id.to_i)
        'Wooohooo - delete all the junk!'
      else
        "Doesn't work this way!"
      end
    end

  end


  command :reply, :trigger, :command do
    desc 'Manage replies. Without trigger, show all trigger. With trigger and' +
      " without command, shows the trigger's values array. Pass an arbitrary" +
      ' string with "add" or an index number with "del" (starts with 0)'

    on_call do
      if trigger
        if bot.replies.has_key?(trigger)
          if command
            if user = bot.config.admin
              case command
              when 'add' then add_reply(trigger, msg.split[3..-1])
              when 'del' then delete_reply(trigger, msg.split[3])
              else "What? Try '#{bot.config.tc}help reply'."
              end
            else
              ['How about no?', 'Go away!', '°.°', '<_<', 'sryly?'].sample
            end
          else
            bot.replies[trigger].map.with_index { |e, i| %(#{i}: "#{e}") } * ', '
          end
        else
          'What is this shit?'
        end
      else
        bot.replies.keys * ', '
      end
    end

  end

end
