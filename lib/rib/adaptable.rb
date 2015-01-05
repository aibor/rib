# coding: utf-8

##
# Adapter module for creating protocol specific connection
# adapter classes. These are used to provide an abstration layer
# between a {RIB::Bot} and a connections to whatever servers.
#
# It has to convert messages from the server into {RIB::Message}
# and needs to provide a method to talk back to the server, which can
# be used by the bot or its modules.

module RIB::Adaptable

  ##
  # @!method initialize(*args)
  #    On instantiation, a connection to the server should be stablished.
  #
  # @!method run_loop
  #   This is the main worker method. It should run infinitely and
  #   create {RIB::MessageHandler} for each received message that should
  #   be processed.
  #
  #   @yieldparam handler [MessageHandler]
  #
  # @!method say(line, target)
  #   Tell `line` to `target` on the server.
  #
  #   @param line [String]
  #   @param target [String]
  #
  # @!method quit(msg)
  #   Disconnect from the server with the specified message.
  #
  #   @param msg [String]

  %i(initialize run_loop say quit).each do |meth|
    define_method(meth) do |*args|
      raise RIB::NotImplementedError.new(meth)
    end
  end

end

