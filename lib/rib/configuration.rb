# coding: utf-8

module RIB

  ##
  # Object for handling all the configuration details. Also allows
  # {Module Modules} to register their own configuration attributes.
  # On instantiation default values are set by calling {#default}.

  class Configuration

    ##
    # Default values for a new instance.

    Defaults = {
      tc: '!',
      admin: '',
      qmsg: 'Bye!',
      logdir: 'log/',
      debug: false,
      modules: {}
    }


    ##
    # Connection adapter specific configuration.
    #
    # @return [Object]

    attr_accessor :connection


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
    # List of {Module} configuration to load. Keys can be module names
    # as Symbol. Values can be of FalseClass: module will not be loaded,
    # or a Hash, which can hold configuration values for the module.
    #
    # @return [Hash, false]

    attr_accessor :modules


    ##
    # On instantiation the {Defaults} are set.

    def initialize(connection_adapter)
      default
      @connection = connection_adapter::Configuration.new
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


    private

    ##
    # Set attribute from within the instance.
    #
    # @param [#to_s] name   name of the attribute
    # @param [Object] value value to assign to the attribute

    def set_attribute(name, value)
      send "#{name}=", (value.dup rescue value)
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

