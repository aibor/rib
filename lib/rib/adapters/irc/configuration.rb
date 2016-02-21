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


  Channel = Struct.new(:name, :log)


  ##
  # Default values for a new instance.

  def initialize
    @server = 'irc.quakenet.org'
    @port = 6667
    @ssl = SSL.new( false, false, '/etc/ssl/certs', '' )
    @nick = 'rib' + rand(999).to_s
    @channels = Hash.new do |hash, key|
      unless key.respond_to? :to_s
        msg = "#{key.class} can not be converted to string"
        raise TypeError.new(msg)
      end
      name = key.to_s
      hash[name]= Channel.new name, false
    end
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
  # List of channels to join.
  #
  # @return [Hash(Symbol => Channel)]

  attr_reader :channels


  ##
  # Customized setter for @channels attribute
  #
  # @params channel_list [Array(Symbol)]
  # @params channel_defs [Hash(Symbol => Object]
  #
  # @return [Hash(Symbol => Channel)]

  def channels=(*channel_list, **channel_defs)
    @channels.clear

    channel_list.flatten.each { |channel| @channels[channel] }
    channel_defs.each do |channel, definition|
      unless definition.is_a? Hash
        msg = "definition for channel '#{name}' must be a Hash"
        raise TypeError.new(msg)
      end
      definition.each { |k,v| @channels[channel][k] = v }
    end

    @channels
  end

end

