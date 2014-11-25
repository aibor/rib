# coding: utf-8

require 'rib'
require 'rib/message_handler'


class RIB::Message 

  attr_reader :text, :user, :source, :module, :command, :arguments

  ##
  #   @param text   [String] text of the message
  #   @param user   [String] user that sent the message
  #   @param source [String] source from where it was received,
  #     e.g. the channel
  
  def initialize(text, user, source)
    @text, @user, @source = text, user, source
    @module = @command = @arguments = nil
  end


  ##
  # Check if the `text` matches the Bot command syntax and return
  # module name (optional), command name and arguments (optional).
  #
  # @return [Array(Symbol, Symbol, Array<String>)] if module name is
  #   included
  # @return [Array(Symbol, Array<String>)] if module name is not included

  def parse(command_prefix)
    /\A#{command_prefix}(?:(\S+)#)?(\S+)(?:\s+(.*))?\z/ =~ self.text
    @module     = $1 ? $1.to_sym : $1
    @command    = $2 ? $2.to_sym : $2
    @arguments  = $3.to_s.split
  end

end

