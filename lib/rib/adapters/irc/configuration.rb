# coding: utf-8


##
# Object for handling all the configuration details. Also allows
# {Module Modules} to register their own configuration attributes.
# On instantiation default values are set by calling {#default}.

class RIB::Adapters::IRC::Configuration

  ##
  # Structure for holding SSL connection details.
  #
  # @attr [Boolean] use use SSL?
  # @attr [Boolean] verify verify server certificte?
  # @attr [String] ca_path path to the certificate authorities file
  # @attr [String] client_cert path to client_cert

  SSL = Struct.new(:use, :verify, :ca_path, :client_cert)


  ##
  # Default values for a new instance.

  def initialize
    @server = 'irc.quakenet.org'
    @port = 6667
    @ssl = SSL.new( false, false, '/etc/ssl/certs', '' )
    @nick = 'rib' + rand(999).to_s
    @channel = '#rib'
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
  # SSL details for the connection.
  #
  # @see SSL
  #
  # @return [SSL]

  attr_accessor :ssl


  ##
  # Nickname to connect as.
  #
  # @return [String]

  attr_accessor :nick


  ##
  # String to send for authentication or password.
  #
  # @protocol [optional]  IRC   string to send to an authentication
  #   service like Nickserv
  #
  # @example Authentication for IRC on QuakeNet
  #   cfg.auth = 'Q@CServe.quakenet.org auth rubybot sEcReTpAsSwOrD'
  #
  # @return [Symbol]

  attr_accessor :auth


  ##
  # Space separated string list of channels to join.
  #
  # @return [String]

  attr_accessor :channel

end

