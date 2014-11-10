# coding: utf-8

require 'rib'
require 'rib/message_handler'


class RIB::Message < Struct.new(:text, :user, :source)

end

