# coding: utf-8

class RIB::Module::Core < RIB::Module

  desc 'Quits the connection and exits'
  def quit
    bot.quit if authorized? && Time.now - bot.starttime > 5
  end


  desc 'Print bot uptime'
  def uptime
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


  desc 'List all available Modules or Commands for a specific Module'
  def list(modul = nil)
    if not modul
      "Available Modules: #{bot.modules.map { |m| m.key } * ', '}"
    elsif mod = bot.modules.find_module(modul)
      "Module commands: #{mod.commands.map(&:name) * ', '}"
    else
      'Unknown module'
    end
  end


  desc 'Print short help text for a command'
  def help(cmd = nil)
    if not cmd
      print_help(self.class, 'help')
    elsif modul = bot.modules.find { |m| m.has_command?(cmd.to_sym) }
      print_help(modul, cmd)
    else
      "Unknown command '#{cmd}'. Try '#{bot.config.tc}list'."
    end
  end


  desc 'Reload all Modules'
  def reload
    if authorized?
      bot.reload_modules ? 'done' : 'Me failed q.q'
    else
      ['How about no?', 'Go away!', '°.°', '<_<', 'sryly?'].sample
    end
  end


  desc 'Print version and source'
  def about
    "RIB version: #{RIB::VERSION} - source: https://github.com/aibor/rib"
  end


  desc 'Run a command for another user'
  def give(user, *command)
    new_msg = msg.dup
    new_msg.text.replace command.join(" ")
    lines = []
    handler = RIB::MessageHandler.new(new_msg) do |line, target|
      lines << "#{user}: #{line.sub(/^#{msg.user}: /, '')}"
    end
    handler.process_for! bot
    lines
  rescue RIB::CommandError => e
    e.message
  end


  private

  def print_help(mod, cmd)
    out     = "Module: #{mod.key}"
    method  = mod.instance_method(cmd)

    unless method.name == method.original_name
      out << " -- Alias for #{bot.config.tc}#{method.original_name}"
      return out
    end

    out << " -- Usage: #{bot.config.tc}#{cmd}" 
    if params = method.parameters.group_by(&:first)
      params_a =  params[:req].to_a.map(&:last)
      params_a << params[:opt].to_a.map { |o| "[#{o.last}]" }
      params_a << params[:rest].to_a.map { |r| "[#{r.last}, ... ]" }
      params_string = params_a.flatten * ' '
      out << " #{params_string}" unless params_string.empty?
    end

    if description = mod.descriptions[method.original_name]
      description.gsub!(/\n/, ' ')
      description.squeeze!(' ')
      out << " -- #{description}"
    end

    return out
  end

end

