# coding: utf-8

require 'rib'


module RIB::NameConvertable

  private

  ##
  # Generate the appropriate file name for a class name.
  #
  # @param klass_name [String] name of a RIB::Module class
  #
  # @return [String] expected file name for that class
  def file_path(klass_name)
    raise TypeError, 'not a String' unless klass_name.is_a?(String)

    parts = klass_name.split('::')
    parts.map! do |part|
      part.gsub!(/((?<=[^A-Z])[A-Z]|(?<=\D)\d)/, '_\1')
      part.downcase
    end
    parts.join('/')
  end

end

