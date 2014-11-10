# coding: utf-8

require 'rib'


##
# A bot framework needs to have a simple way to add functionality to
# it. The Module class is inteded to provide a DSL for writing
# Modules for the bot. It handles definition of Commands, Responses
# and Helpers, either for all protocols or only for specific ones.
#
# ## Commands
#
# Commands are called by name with optional parameters, which can have
# names defined. Commands should have a short description which is
# used for help texts. They need to have a block that is called on
# invocation, otherwise there would be no point for a Command.
# See {Command#call} for available methods in {Action#on_call
# Command#on_call} blocks.
#
# ## Responses
#
# Responses are very similar to Commands, but are not called by name.
# They are triggered, if a message matches their trigger regular
# expression. Definition is almost the same as for Commands, but take
# a trigger regular expression instead of parameters. See below for
# an example.
# See {Response#call} for available methods in {Action#on_call
# Response#on_call} blocks.
#
# @example HTML title fetching module
#   RIB::Module.new :title do
#     desc 'Handle automatic HTML title fetching for received URLs.'
#
#     # add a new config attribute and pass it a value
#     on_load do |bot|
#       bot.config.register(:title, true)
#     end
#
#     # define some helper methods which can be used in on_call
#     # blocks
#     helpers do
#       def fetch_title(url)
#         # code for fetching and parsing web pages for HTML titles
#       end
#     end
#
#     # define a new command '!title' which takes one named argument
#     command :title, :on_off do
#       desc 'De-/Activate automatic HTML title fetching'
#       # what will be done when the command is called?
#       on_call do
#         # call the argument by its name
#         case on_off
#         when on
#           # use your added config attribute
#           bot.config.title = true
#           "HTML title fetching activated"
#         when off
#           bot.config.title = false
#           "HTML title fetching deactivated"
#         else
#           "#{user}, I don't understand you"
#         end
#       end
#     end
#
#     # define a new response for messages that contain an URL
#     response :title, %r((http://\S+)) do
#       desc 'automatically fetch and send the HTML title'
#       on_call do
#         # get the value of the regexp's MatchData with match
#         "Title: #{fetch_title(match[1])}"
#       end
#     end
#
#     # some stuff might only work with a particular protocol
#     protocol_only :irc do
#
#       command :formating do
#         desc 'A Command that only works in IRC, maybe due to' +
#           ' formatting special characters'
#         on_call do
#           # fancy stuff
#         end
#       end
#
#     end
#
#   end
#
# @see Action
# @see Command
# @see Response

module RIB::Module

  extend RIB::Helpers
  extend self

  autoload :Base, 'rib/module/base'

  Directory = File.expand_path("../module/*.rb", __FILE__)


  ##
  # Load a file or  directory. If they contain RIB::Modules, they
  # are instantiated and added to the 'loaded' attribute.
  #
  # @param [String] path
  #
  # @return [Array<String>] found and loaded files

  def load_all
    Dir[Directory].each { |f| load f }
    loaded
  end


  def loaded(name_only = false)
    self.constants.map do |constant_name|
      constant = self.const_get(constant_name)
      next unless constant.is_a?(Class)
      next unless constant.superclass == self.const_get(:Base)
      name_only ? constant_name : constant
    end.compact
  end

end

