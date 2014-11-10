# coding: utf-8

require 'rib'
require 'rib/message'


class RIB::MessageHandler

  attr_reader :msg


  def initialize(*args)
    @msg = RIB::Message.new(*args)
  end


  def process(modules, tc)
    command, arguments = parse_msg(tc)
    if command
      resp = modules.select do |modul|
        modul.respond_to?(command) &&
          _method_takes_args?(modul.method(command), arguments.count)
      end
      if resp.count > 1
        say "Ambigious command. Modules: '%s'. Use '%sModulname#%s'" %
          [resp.map { |m| m.class.key.inspect } * ', ', tc, command]
      elsif resp.one?
        say call_command(resp.first.dup, command, arguments)
      end
    else
      responses(modules, msg.text) do |modul, command, arguments|
        if _method_takes_args?(modul.method(command), arguments.count)
          say call_command(modul.dup, command, arguments)
        end
      end
    end
  end


  def tell(&block)
    @say = block
  end


  def logger=(logger)
    if logger.is_a?(Logger)
      @log = logger
      @log.progname ||= self.class.name
    end
  end


  private

  def _method_takes_args?(method, args_count)
    params = method.parameters.group_by(&:first)
    params_min = params[:req].to_a.count
    params_max = params_min + params[:opt].to_a.count
    params[:rest] || args_count.between?(params_min, params_max)
  end


  def responses(modules, text)
    modules.each do |modul|
      next unless modul.class.responses
      modul.class.responses.each do |trigger, cmd|
        match = trigger.match(text)
        yield(modul, cmd, match.captures) if match
      end
    end
  end


  def parse_msg(tc)
    if /\A#{tc}(\S+)(?:\s+(.*))?\z/ =~ self.msg.text
      cmd, args = $1.to_sym, $2.to_s.split
    end
  end


  def call_command(modul, name, args = [])
    modul.msg_queue.push(self.msg)
    modul.new_msg = true
    timeout(modul.class.timeouts[name]) { modul.send(name, *args) }
  rescue Timeout::Error
    @log.warn "message processing took too long: '#{msg.text}'." if @log
    nil
  rescue => e
    if @log
      @log.warn "Error while processing command: #{name}"
      @log.warn e
    end
    nil
  end


  def say(*args)
    text, target = args.count == 2 ? args : [args * ' ', nil]
    text.to_s.split("\n").each do |line|
      @log.debug "say: '#{line}' to '#{target}'"
      @say.call(line, target)
    end
  end

end

