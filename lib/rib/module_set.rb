# coding: utf-8

require 'rib'
require 'set'


##
# Specialized Set for carrying our loaded and desired module classes.

class RIB::ModuleSet < ::Set

  ##
  # Bot protocol this Set is used for. (:irc odr :xmpp)
  #
  # @return [Symbol, nil]

  attr_reader :protocol


  ##
  # @param module_names [Array<Symbol>]
  # @param protocol [Symbol]

  def initialize(module_names, protocol = nil)
    @protocol = protocol

    modules = RIB::Module.loaded.select do |modul|
      module_names.include?(modul.key) && modul.speaks?(protocol)
    end

    super(modules)
  end


  ##
  # Find all modules, that respond to a given command name and allow
  # the given number of arguments.
  #
  # @param cmd_name [Symbol]
  # @param args [Array<String>]
  #
  # @return [Array<Class>]

  def responding_modules(cmd_name, args)
    @hash.select do |modul, state|
      state && modul.has_command_for_args?(cmd_name, args.count)
    end.keys
  end


  ##
  # Find a module woth the given name
  #
  # @param name [#to_s]
  # 
  # @return [Class, nil]

  def find_module(name)
    modul = @hash.find do |mod, state|
      state && mod.key.to_s.casecmp(name.to_s).zero?
    end
    modul.first if modul
  end


  ##
  # Find all triggers that match the given text. In order to avoid
  # running the regexp again against the text, return the MatchData
  # along with the block for the trigger.
  #
  # @param text [String]
  #
  # @return [Hash{Class => Array<Array(Proc,MatchData)>]

  def matching_triggers(text)
    seed = Hash.new([])
    @hash.inject(seed) do |hsh, (modul, state)|
      modul.triggers.each do |trigger, block|
        match = trigger.match(text)
        hsh[modul] += [[block, match]] if state && match
      end
      hsh
    end
  end

end

