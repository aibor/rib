# coding: utf-8

require 'rib'
require 'rib/message_handler'


class RIB::Message < Struct.new(:text, :user, :source)

  ##
  # @!method initialize(text = nil, user = nil, source = nil)
  #   @param text   [String] text of the message
  #   @param user   [String] user that sent the message
  #   @param source [String] source from where it was received,
  #     e.g. the channel


end

