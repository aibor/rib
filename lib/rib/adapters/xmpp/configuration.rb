# coding: utf-8


##
# Object for handling all the configuration details. Also allows
# {Module Modules} to register their own configuration attributes.
# On instantiation default values are set by calling {#default}.

class RIB::Adapters::XMPP::Configuration

  ##
  # Default values for a new instance.

  def initialize 
    @port = 5222
    @resource = 'rib'
    @jid = 'rib' + rand(999).to_s + '@jabber.org'
    @channel = '#rib'
    @password = 'seCreT'
  end


  ##
  # Hostname or IP address of the server to connect to.
  #
  # @return [String]

  attr_accessor :server


  ##
  # Port to connect to.
  #
  # @return [Fixnum]

  attr_accessor :port


  ##
  # Resource to connect as.
  #
  # @return [String]

  attr_accessor :resource


  ##
  # @return [Symbol]

  attr_accessor :password


  ##
  # @return [String]

  attr_accessor :jid

  ##
  # Space separated string list of channels to join.
  #
  # @return [String]

  attr_accessor :muc

end

