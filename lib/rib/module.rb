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
# {Module}. Commands should have a short description which is
# used for help texts. Additional helper methods may be defined, but
# should be private.
#
# ## Triggers
#
# Triggers are called, if a message matches their trigger regular
# expression. Definition is done by giving a regular expression and a
# block, which shall be called, wenn a message matches the regular
# expression. The MatchData object is passed to te block, so capture
# groups can be used in any way Ruby allows.
#
# @example HTML title fetching module
#   class LinkTitle < RIB::Module
#
#     # add a new config attribute and pass it a value
#     register title: true
#
#
#     # define a new command '!title' which takes one named argument
#     desc 'De-/Activate automatic HTML title fetching'
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

class RIB::Module

  Directory = File.expand_path("../modules/*.rb", __FILE__)


  ##
  # The bot instance the module is called for.
  #
  # @return [Bot]

  attr_reader :bot


  ##
  # The message the module is called for.
  #
  # @return [Message]

  attr_reader :msg


  ##
  # @param bot [Bot]
  # @param msg [Message]

  def initialize(bot, msg)
    @bot, @msg = bot, msg
  end


  private

  ##
  # Logger that can be used for convenient logging from a module.
  #
  # @return [Logger]

  def logger
    unless @logger
      @logger = bot.logger.dup
      @logger.progname = self.class.name
    end
    @logger
  end


  ##
  # Check if the requesting user is the admin.

  def authorized?
    msg.user == bot.config.admin
  end


  ##
  # Class singleton methods

  class << self

    ##
    # Load all modules in a directory.
    #
    # @param [String] path
    #
    # @return [Array<String>] found and loaded files

    def load_all(path = Directory)
      old_verbose = $VERBOSE
      $VERBOSE = nil
      Dir[path].each { |f| load f }
      $VERBOSE = old_verbose
      loaded
    end


    ##
    # Set that holds all subclasses of {Module}, which are Bot modules.
    #
    # @return [Set<Object>] either the Instances or just their base
    #   class names

    def loaded
      @loaded ||= ::Set.new
    end


    private

    ##
    # @private
    # callback method
    
    def inherited(subclass)
      loaded << subclass
      subclass.extend(RIB::ModuleMethods)
      super
    end


    ##
    # @private
    # callback method
    
    def method_added(method_name)
      if @next_description ||= nil
        descriptions[method_name] = @next_description
        @next_description = nil
      end
    end

  end

end

