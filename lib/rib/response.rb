# coding: utf-8

require 'rib/helpers'
require 'rib/action'

module RIB

  class Response < Action

    ##
    # The regular expression that triggers invocation of this instance.
    # Just like with any regular expression, it can have capture groups.
    # These will be available in the {Action#action #on_call} block via
    # the method `#match`.
    #
    # @return [Regexp]

    attr_reader :trigger


    ##
    # @param [#to_sym] name
    #   name of the Command
    # @param [Symbol] mod_name
    #   name of the Module that Command belongs to
    # @param [Regexp] trigger
    #   regular expression that triggers this Response
    # @param [Symbol, Array<Symbol>] protocol
    #   none or several protocols this command is limited to

    def initialize(name, mod_name, trigger, protocol = nil, &block)
      @trigger   = trigger

      super(name, mod_name, protocol, &block)
    end


    ##
    # (see Action#call)
    #
    # Also the match data, and therefore any capture groups from the
    # trigger's regular expression, can be called via #match inside the
    # block. This method returns a MatchData object.
    #
    # @see http://www.ruby-doc.org/core-2.1.2/MatchData.html MatchData
    #   Documentation

    def call(hash)
      super(hash.merge(match: hash[:msg].match(@trigger)))
    end

  end

end
