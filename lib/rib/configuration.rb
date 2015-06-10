# coding: utf-8

module RIB

  ##
  # Object for handling all the configuration details. Also allows
  # {Module Modules} to register their own configuration attributes.
  # On instantiation default values are set by calling {#default}.

  class Configuration

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

    Defaults = {
      protocol:      :irc,
      server:        'irc.quakenet.org',
      port:          6667,
      ssl:           SSL.new( false, false, '/etc/ssl/certs', '' ),
      nick:          'rib' + rand(999).to_s,
      jid:           'rubybot@xmpp.example.com',
      channel:       '#rib',
      tc:            '!',
      admin:         '',
      qmsg:          'Bye!',
      logdir:        'log/',
      debug:         false,
      modules:       [:Core, :LinkTitle, :Search, :Alarm, :Fun, :Quotes,
                      :Seen, :Fact]
    }


    ##
    # Add new configuration attribute for this Configuration instance.
    # This method is intended to be used by {Module Modules} in order
    # to register their own configuration directives.
    #
    # @param attr  [Symbol] name of the new attribute
    # @param value [Object] value to assign to the new attribute
    #
    # @raise [TypeError] if attr is not a Symbol
    #
    # @return [Object] the value

    def self.register(attr, value = nil)
      if attr.is_a?(Symbol)
        Defaults[attr] = value
      else
        raise TypeError, "not a Symbol: #{attr.inspect}"
      end
    end


    ##
    # Protocol of the connection to use. Should be `:irc` or `:xmpp`.
    #
    # @return [Symbol]

    attr_accessor :protocol



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
    # JID to authenticate as.
    #
    # @protocol_only xmpp
    #
    # @return [Symbol]

    attr_accessor :jid


    ##
    # String to send for authentication or password.
    #
    # @protocol [mandatory] XMPP  password for the {#jid JID}
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


    ##
    # Trigger character as prefix for commands.
    #
    # @return [Character]

    attr_accessor :tc


    ##
    # Nickname of the admin. The user with this nickname is allowed to
    # execute managing commands, like letting the bot join/part
    # channels, quitting or changing configuration values.
    #
    # @return [String]

    attr_accessor :admin


    ##
    # Message to send when quitting.
    #
    # @return [String]

    attr_accessor :qmsg


    ##
    # Directory where the logfiles will be created. Might be an
    # absolute path or a relative path to the directory the main
    # application file is stored.
    #
    # @return [String]

    attr_accessor :logdir


    ##
    # In debug mode the bot is more verbose and logs to stdout instead
    # of the logfiles.
    #
    # @return [Boolean]

    attr_accessor :debug


    ##
    # List of {Module Modules} to load.
    #
    # @return [Array<Symbol>]

    attr_accessor :modules


    ##
    # On instantiation the {Defaults} are set.

    def initialize
      default
    end


    ##
    # Check if this instance has a specific attribute set.
    #
    # @param [#to_s] attr name of the attribute
    #
    # @return [Boolean] attribute is known?

    def has_attr?(attr)
      instance_variables.any? { |e| e[/@#{attr}/] }
    end


    ##
    # Check if this instance has a specific attribute set and also
    # check if it has a value.
    #
    # @param [#to_s] attr name of the attribute
    #
    # @return [Boolean] attribute is defined?

    def defined?(attr)
      has_attr?(attr) && !send(attr).nil?
    end


    ##
    # Add new configuration attribute for this Configuration instance.
    # This method is intended to be used by {Module Modules} in order
    # to register their own configuration directives.
    #
    # @param [Symbol] attr  name of the new attribute
    # @param [Object] value value to assign to the new attribute
    #
    # @raise [TypeError] if attr is not a Symbol
    # @raise [AttributeExistsError] if the an attribute with that name
    #   already exists
    #
    # @return [nil]

    def register(attr, value = nil)
      raise TypeError, 'not a Symbol' unless attr.is_a? Symbol
      raise AttributeExistsError.new(attr) if has_attr?(attr)
      raise ReservedNameError.new(attr) if respond_to?(attr)

      singleton_class.class_eval { attr_accessor attr }
      set_attribute(attr, value)
    end


    private

    ##
    # Set attribute from within the instance.
    #
    # @param [#to_s] name   name of the attribute
    # @param [Object] value value to assign to the attribute

    def set_attribute(name, value)
      send("#{name}=", value.respond_to?(:dup) ? value.dup : value)
    end


    ##
    # Read and set {Defaults}.
    #
    # @return [Hash] {Defaults}

    def default
      Defaults.each do |key, value|
        register(key) unless respond_to?(key)
        set_attribute(key, value)
      end
    end

  end

end

