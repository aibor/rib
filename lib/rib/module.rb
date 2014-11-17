# coding: utf-8

require 'rib'
require 'set'


##
# A bot framework needs to have a simple way to add functionality to
# it. The Module class is inteded to provide a simple way for writing
# Modules for the bot. It handles definition of Commands and Triggers,
# either for all protocols or only for specific ones.
#
# ## Commands
#
# Commands are all public instance methods defined in a subclass of
# {Module::Base}. Commands should have a short description which is
# used for help texts. Additional helper methods may be defined, but
# should be private.
# See {Module::Base} for available predefined helper methods.
#
# ## Triggers
#
# Triggers are very similar to Commands, but are not called by name.
# They are triggered, if a message matches their trigger regular
# expression. Definition is done by giving a regular expression and a
# block, which shall be called, wenn a message matches the regular
# expression. The MatchData object is passed to te block, so capture
# groups can be used in any way Ruby allows.
#
# @example HTML title fetching module
#   class LinkTitle < RIB::Module::Base
#
#     # describe the Module
#     describe 'Handle automatic HTML title fetching for URLs.'
#
#
#     # add a new config attribute and pass it a value
#     register title: true
#
#
#     # define a new command '!title' which takes one named argument
#     describe title: 'De-/Activate automatic HTML title fetching'
#
#     def title(on_off)
#       case on_off
#       when on
#         # use your added config attribute
#         bot.config.title = true
#         "HTML title fetching activated"
#       when off
#         bot.config.title = false
#         "HTML title fetching deactivated"
#       else
#         "#{user}, I don't understand you"
#       end
#     end
#
#
#     # define a new response for messages that contain an URL
#     response %r((http://\S+)) do |match|
#       # get the value of the regexp's MatchData with match
#       "Title: #{fetch_title(match[1])}"
#     end
#
#
#     # some stuff might only work with a particular protocol
#     protocol_only :irc do
#
#       desc formatting: 'A Command that only works in IRC, maybe due' +
#         ' to formatting special characters'
#
#       def formatting
#         # fancy stuff
#       end
#
#     end
#
#
#     private
#
#     # define some helper methods which can be used in on_call
#     # blocks
#     def fetch_title(url)
#       # code for fetching and parsing web pages for HTML titles
#     end
#
#   end
#
# @see Module::Base
# @see Command
# @see Trigger

module RIB::Module

  extend RIB::Helpers
  extend self

  autoload :Base, 'rib/module/base'

  Directory = File.expand_path("../module/*.rb", __FILE__)


  ##
  # Load all modules in a directory.
  #
  # @param [String] path
  #
  # @return [Array<String>] found and loaded files

  def load_all(path = Directory)
    Dir[path].each { |f| load f }
    loaded
  end


  ##
  # Set that holds all subclasses of {Module::Base}, which are
  # Bot modules.
  #
  # @param name_only [Boolean] if only the class names without namespace
  #   prfix should be returned
  #
  # @return [Set<Object>] either the Instances or just their base class
  #   names

  def loaded(name_only = false)
    @loaded ||= ::Set.new
    name_only ? @loaded.map(&:key).to_set : @loaded
  end


  class Set < ::Set

    attr_reader :protocol

    def initialize(module_names, protocol = nil)
      @protocol = protocol

      modules = RIB::Module.loaded.select do |modul|
        module_names.include?(modul.key) && modul.speaks?(protocol)
      end

      super(modules)
    end


    def responding_modules(cmd_name, args)
      @hash.select do |modul, state|
        state && modul.has_command_for_args?(cmd_name, args.count)
      end.keys
    end


    def find_module(name)
      modul = @hash.find do |modul, state|
        state && modul.key.to_s.casecmp(name.to_s).zero?
      end
      modul.first if modul
    end


    def matching_triggers(text)
      @hash.inject(Hash.new([])) do |hsh, (modul, state)|
        modul.triggers.each do |trigger, block|
          match = trigger.match(text)
          hsh[modul] += [[block, match]] if state && match
        end
      end
    end

  end

end

