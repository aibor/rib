# coding: utf-8

require 'rib'
require 'rib/message'


##
# Class for handling received messages. On instantiation, a
# {RIB::Message} is created and passed to the {RIB::Module}
# that matches the command or trigger on the message.

class RIB::MessageHandler

  ##
  # The handled {Message}.
  #
  # @return [Message]

  attr_reader :msg


  ##
  # @param msg [Message] message to parse and handle
  #
  # @yieldparam line   [String] reply to send
  # @yieldparam target [String] receiver of the message, e.g a nick

  def initialize(msg, &block)
    raise TypeError, 'not a RIB::Message' unless msg.is_a?(RIB::Message)
    @msg, @say, @bot = msg, block, nil
  end


  ##
  # Parse the message and check if it looks like a command or if a
  # trigger matches. Before this method can be used, a block 
  #
  # @param modules [Set<Module>] modules which should be searched
  # @param tc      [String] character that prefixes Bot commands

  def process(bot)
    @bot = bot

    mod_name, cmd_name, args = parse_msg

    if mod_name
      lookup_module(mod_name, cmd_name, args)
    elsif cmd_name
      lookup_command(cmd_name, args)
    else
      process_triggers
    end
  end


  private

  def lookup_module(mod_name, cmd_name, args)
    if modul = @bot.modules.find_module(mod_name)
      if modul.has_command_for_args?(cmd_name, args.count)
        say call_command(modul, cmd_name, args)
      else
        say "No appropriate command found for module '%s'." % modul
      end
    else
      say "Unknown Module: '#{mod_name}'"
    end
  end


  ##
  # Try to find a {Module}, that is able to handle the command with
  # its arguments. If multiple {Module Modules} are found, tel the user
  # to invokethe command pefixed with its {Module} name.
  #
  # @param cmd_name [Symbol]        command name to search for
  # @param args     [Array<String>] arguments that shall be passed to
  #   found method
  #
  # @return [void]

  def lookup_command(cmd_name, args)
    moduls = @bot.modules.responding_modules(cmd_name, args)

    if moduls.count > 1
      say "Ambigious command. Modules: '%s'. Use '%sModulname#%s'" %
        [moduls.map(&:key) * ', ', @bot.config.tc, cmd_name]
    elsif moduls.one?
      say call_command(moduls.first, cmd_name, args)
    else
      say "Unknown command '#{cmd_name}'", @msg.user
    end
  end


  ##
  # Find triggers that matches, call their block and {#say} their
  # response.
  #
  # @return [void]

  def process_triggers
    modules = bot.modules.matching_triggers(@msg.text)

    modules.each do |modul, trigger_block_array|
      obj = modul_instance(modul)
      trigger_block_array.each do |block, match|
        timeout = modul.timeouts[match.regexp]
        call_with_timeout(timeout, match) do
          say obj.instance_exec(match, &block)
        end
      end
    end
  end


  def call_with_timeout(timeout, *args)
    timeout(timeout) { yield *args }
  rescue Timeout::Error
    @bot.logger.warn "message processing took too long: '#{msg.text}'."
  rescue => e
    @bot.logger.warn "Error while processing msg: #{name}"
    @bot.logger.warn e
  end


  ##
  # Call the command for a {Module} with the specified arguments. If the
  # called method takes too long, an error is logged and nothing nil is
  # returned.
  #
  # @param modul [Module]
  # @param name  [Symbol]        command name
  # @param args  [Array<String>] arguments to pass
  #
  # @return [String]                text to reply
  # @return [Array(String, String)] text and target to reply to

  def call_command(modul, name, args = [])
    timeout = modul.timeouts[name]
    timeout(timeout) { module_instance(modul).send(name, *args) }
  rescue Timeout::Error
    @bot.logger.warn "message processing took too long: '#{msg.text}'."
    nil
  rescue => e
    @bot.logger.warn "Error while processing command: #{name}"
    @bot.logger.warn e
    nil
  end


  ##
  # Check if the `@msg.text` matches the Bot command syntax and return
  # module name (optional), command name and arguments (optional).
  #
  # @return [(Symbol, Symbol, Array<String>] if module name is included
  # @return [(Symbol, Array<String>] if module name is not included

  def parse_msg
    if /\A#{@bot.config.tc}(?:(\S+)#)?(\S+)(?:\s+(.*))?\z/ =~ @msg.text
      [$1 ? $1.to_sym : $1, $2.to_sym, $3.to_s.split]
    end
  end


  def say(*args)
    text, target = args.count == 2 ? args : [args * ' ', nil]
    text.to_s.split("\n").each do |line|
      @bot.logger.debug "say: '#{line}' to '#{target}'"
      @say ? @say.call(line, target) : @bot.say(line, target)
    end
  end


  def module_instance(modul)
    modul.new(@bot, @msg)
  end

end

