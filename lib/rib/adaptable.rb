# coding: utf-8

##
# Adapter module for creating protocol specific connection
# adapter classes. These are used to provide an abstration layer
# between a {RIB::Bot} and a {RIB::Connection}.

module RIB::Adaptable

  extend RIB::NameConvertable


  def self.included(klass)
    path = "#{file_path(klass.name)}/connection"
    klass.autoload(:Connection, path)
  end


  %i(initialize run_loop say).each do |meth|
    define_method(meth) do |*args|
      raise RIB::NotImplementedError.new(meth)
    end
  end

end

