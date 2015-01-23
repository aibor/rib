# coding: utf-8

require 'rib'


##
# Class for handling received messages. On instantiation, a
# {RIB::Message} is created and passed to the {RIB::Module}
# that matches the command or trigger on the message.

class RIB::MessageHandler

  Messages = {
    wrong_args: "%s: Wrong number of arguments. Try '%chelp %s'.",
    no_module: "%s: Unknown Module: '%s'",
    no_command: "%s: No appropriate command found for module '%s'.",
    ambigous_command: 
    "%s: Ambigious command. Modules: '%s'. Use '%sModulname#%s'"
  }


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

  def process_for(bot)
    @bot = bot

    @msg.parse(@bot.config.tc)

    if @msg.module
      say process_module
    elsif @msg.command
      say process_command
    else
      process_triggers { |response| say response }
    end
  end


  private

  ##
  # Try to call the requested command for the Module with the given
  # name. Return something to respond to the requesting user.
  #
  # @return [String, Array(String, String)] response for @say block
  # @return [nil] if nothing should be responded

  def process_module
    if not modul = @bot.modules.find_module(@msg.module)
      Messages[:no_module] % [@msg.user, @msg.module]
    elsif modul.has_command?(@msg.command)
      if modul.command_takes_args?(@msg.command, @msg.arguments.count)
        call_command(modul)
      else
        Messages[:wrong_args] % [@msg.user, @bot.config.tc, @msg.command]
      end
    else
      Messages[:no_command] % [@msg.user, modul]
    end
  end


  ##
  # Try to find a {Module}, that is able to handle the command with
  # its arguments. If multiple {Module Modules} are found, tell the user
  # to invokethe command pefixed with the desired {Module} name.
  #
  # @return [String, Array(String, String)] response for @say block
  # @return [nil] if nothing should be responded

  def process_command
    moduls = @bot.modules.select_responding(@msg.command)

    return if moduls.empty?

    mods = moduls.select do |mod|
      mod.command_takes_args?(@msg.command, @msg.arguments.count)
    end

    if mods.count > 1
      Messages[:ambigous_command] %
        [@msg.user, mods.map(&:key) * ', ', @bot.config.tc, @msg.command]
    elsif mods.one?
      call_command(mods.first)
    else
      Messages[:wrong_args] % [@msg.user, @bot.config.tc, @msg.command]
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
    triggered = @bot.modules.matching_triggers(@msg.text)

    triggered.each do |modul, trigger_block_array|
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
  #
  # @return [String]                text to reply
  # @return [Array(String, String)] text and target to reply to
  # @return [nil] if nothing should be responded

  def call_command(modul)
    call_with_timeout(modul.timeouts[@msg.command]) do
      module_instance(modul).send(@msg.command, *@msg.arguments)
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

