# coding: utf-8

require 'rib'


module RIB::Helpers

  private

  ##
  # @param [Object] object  an object to check
  #
  # @return [TrueClass] object passed the check
  #
  # @raise [TypeError] if object isn't a Symbol or Array of Symbols
  def ensure_symbol_or_array_of_symbols(object)
    case object
    when Symbol then true
    when Array then object.all? {|e| e.is_a? Symbol}
    else raise TypeError, 'not a Symbol or Array of Symbols'
    end
  end


  ##
  # Generate the appropriate file name for a class name.
  #
  # @param klass_name [String] name of a RIB::Module class
  #
  # @return [String] expected file name for that class
  def to_file_path(klass_name)
    raise TypeError, 'not a String' unless klass_name.is_a?(String)

    parts = klass_name.split('::')
    parts.map! do |part|
      part.gsub!(/((?<=[^A-Z])[A-Z]|(?<=\D)\d)/, '_\1')
      part.downcase
    end
    parts.join('/')
  end

end

