# coding: utf-8

class RIB::Module::Core < RIB::Module

  describe 'Core Module'


  describe quit: 'Quits the connection and exits'

  def quit
    if authorized? && Time.now - bot.starttime > 5
      bot.connection.quit(bot.config.qmsg)
      bot.connection.stop_ping_thread
      exit
    end
  end


  describe uptime: 'Print bot uptime'

  def uptime
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


  describe list: 'List all available Modules or Commands for a specific Module'

  def list(modul = nil)
    if modul
      mod = bot.modules.find_module(modul)
      mod ? "Module commands: #{mod.commands * ', '}" : 'Unknown module'
    else
      "Available Modules: #{bot.modules.map { |m| m.key } * ', '}"
    end
  end


  describe help: 'Print short help text for a command'

  def help(cmd = nil)
    if cmd
      modul = bot.modules.find { |m| m.commands.include?(cmd.to_sym) }
      if modul
        print_help(modul, cmd)
      else
        "Unknown command '#{cmd}'. Try '#{bot.config.tc}list'."
      end
    else
      print_help(self.class, 'help')
    end
  end


  describe reload: 'Reload all Modules'

  def reload
    if authorized?
      bot.reload_modules ? 'done' : 'Me failed q.q'
    else
      ['How about no?', 'Go away!', '°.°', '<_<', 'sryly?'].sample
    end
  end



  describe join: 'Join a new channel'

  def join(channel)
    bot.connection.join_channel(channel) if authorized?
  end


  describe part: 'Leave a channel. If none specified, leave the one 
    the command was received from.'

  def part(channel = nil)
    channel ||= msg.source
    bot.connection.part(channel) if authorized?
  end



  private

  def print_help(mod, cmd)
    out     = "Module: #{mod.key}"
    method  = mod.instance_method(cmd)

    if method.name == method.original_name
      params = method.parameters.group_by(&:first)
      params_a =  params[:req].to_a.map(&:last)
      params_a << params[:opt].to_a.map { |o| "[#{o.last}]" }
      params_a << params[:rest].to_a.map { |r| "[#{r.last}, ... ]" }
      params_string = params_a.flatten * ' '

      description = mod.descriptions[method.original_name]
      description.gsub!(/\n/, ' ')
      description.squeeze!(' ')

      out << " -- Usage: #{bot.config.tc}#{cmd}" 
      out << " #{params_string}" unless params_string.empty?
      out << " -- #{description}" if description
    else
      out << " -- Alias for #{bot.config.tc}#{method.original_name}"
    end
  end


  def authorized?
    msg.user == bot.config.admin
  end

end

