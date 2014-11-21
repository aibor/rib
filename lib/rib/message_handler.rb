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
  # trigger matches.
  #
  # @param bot [Bot] instance to process this message for

  def process(bot)
    @bot = bot

    mod_name, cmd_name, args = parse_msg

    if mod_name
      say lookup_module(mod_name, cmd_name, args)
    elsif cmd_name
      say lookup_command(cmd_name, args)
    else
      process_triggers { |response| say response }
    end
  end


  private

  ##
  # Try to call the requested command for the Module with the given
  # name. Return something to respond to the requesting user.
  #
  # @param mod_name [Symbol] name of a module to call the cmd for
  # @param cmd_name [Symbol] name of the command to call
  # @param args [Array<String>] arguments to pass to the command
  #
  # @return [String, Array(String, String)] response for @say block
  # @return [nil] if nothing should be responded

  def lookup_module(mod_name, cmd_name, args)
    if modul = @bot.modules.find_module(mod_name)
      if modul.has_command_for_args?(cmd_name, args.count)
        call_command(modul, cmd_name, args)
      else
        "%s: No appropriate command found for module '%s'." %
          [@msg.user, modul]
      end
    else
      "#{@msg.user}: Unknown Module: '#{mod_name}'"
    end
  end


  ##
  # Try to find a {Module}, that is able to handle the command with
  # its arguments. If multiple {Module Modules} are found, tell the user
  # to invokethe command pefixed with the desired {Module} name.
  #
  # @param cmd_name [Symbol]        command name to search for
  # @param args     [Array<String>] arguments that shall be passed to
  #   found method
  #
  # @return [String, Array(String, String)] response for @say block
  # @return [nil] if nothing should be responded

  def lookup_command(cmd_name, args)
    moduls = @bot.modules.responding_modules(cmd_name, args)

    if moduls.count > 1
      "%s: Ambigious command. Modules: '%s'. Use '%sModulname#%s'" %
        [@msg.user, moduls.map(&:key) * ', ', @bot.config.tc, cmd_name]
    elsif moduls.one?
      call_command(moduls.first, cmd_name, args)
    else
      "#{@msg.user}: Unknown command '#{cmd_name}'"
    end
  end


  ##
  # Find triggers that matches, call their block and yield the passed
  # block with their response. Block should be something like:
  # `{ |response| say response }`.
  #
  # @yieldparam response [Object] return value of the block of a
  #   matching trigger
  #
  # @return [void]

  def process_triggers
    modules = @bot.modules.matching_triggers(@msg.text)

    modules.each do |modul, trigger_block_array|
      obj = module_instance(modul)
      trigger_block_array.each do |block, match|
        timeout = modul.timeouts[match.regexp]
        call_with_timeout(timeout) do
          yield obj.instance_exec(match, &block)
        end
      end
    end
  end


  ##
  # Wrap a block into a timeout and do some logging on failures.
  #
  # @param timeout [Fixnum]
  #
  # @yield
  #
  # @return [Object] retun value of the passed block

  def call_with_timeout(timeout, &block)
    timeout(timeout, &block)
  rescue Timeout::Error
    @bot.logger.warn "message processing took too long: '#{@msg.text}'."
    nil
  rescue => e
    @bot.logger.warn "Error while processing msg: #{@msg.text}"
    @bot.logger.warn e
    nil
  end


  ##
  # Call the command for a {Module} with the specified arguments. If the
  # called method takes too long, an error is logged and nothing nil is
  # returned.
  #
  # @param modul [Class]         a RIB::Module
  # @param name  [Symbol]        command name
  # @param args  [Array<String>] arguments to pass
  #
  # @return [String]                text to reply
  # @return [Array(String, String)] text and target to reply to
  # @return [nil] if nothing should be responded

  def call_command(modul, name, args = [])
    timeout = modul.timeouts[name]
    call_with_timeout(timeout) { module_instance(modul).send(name, *args) }
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


  ##
  # Let the Bot speak to the channel, or user.
  #
  # @param args [Array<String>]  
  #
  # @return [void]

  def say(*args)
    text, target = args.count == 2 ? args : [args * ' ', nil]
    text.to_s.split("\n").each do |line|
      @bot.logger.debug "say: '#{line}' to '#{target}'"
      @say ? @say.call(line, target) : @bot.say(line, target)
    end
  end


  ##
  # Create an instance of a {Module} which can be used for further
  # message processing.
  #
  # @param modul [Class] a RIB::Module
  #
  # @return [Object] instance of the passed Class

  def module_instance(modul)
    modul.new(@bot, @msg)
  end

end

