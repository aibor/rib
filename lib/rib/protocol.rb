# coding: utf-8

require 'rib'


##
# This module handles the Connection Protocols. Each has to provide
# a `Connection` class in its namespace, which inherits from
# {RIB::Connection::Base}. Also, a protocol is included by {Bot} and
# therefore has to avoid unintended naming collisions.

module RIB::Protocol

  class Adapter

    extend RIB::Helpers

    attr_reader :connection

  end

end

