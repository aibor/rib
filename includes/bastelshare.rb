require 'rexml/document'
require 'open-uri'

class Bastelshare

  Media = Struct.new(:name, :url, :size, :length, :format)

  DefaultResource = 'https://bastelfreak.de/files/'

  def initialize( resource = DefaultResource )
    @resource = resource
  end

  def refresh( min = 60 )
    return false if @last_refresh and @last_refresh > (Time.new - min * 60)
    refresh!
  end

  def refresh!
    xml = fetch_xml( @resource )
    parse_xml( xml )
    @last_refresh = Time.new
  end

  def [](x)
    @media[x]
  end

  def find( string = "" )
    return nil unless @media and string
    re = Regexp.new(string, true)
    @media.select {|m| m.name =~ re}
  end

  def method_missing(method_name, *args)
    plurals = Media.members.map {|m| m.to_s.sub(/([^s])$/, '\1s')}
    index = plurals.index(method_name.to_s)
    if index
      @media.map {|m| m[index]}
    else
      super
    end
  end

private

  def fetch_xml( resource )
    REXML::Document.new( open( resource ).read )
  end

  def parse_xml( xml )
    @media = Array.new
    xml.root.elements.each("file") do |file|
      general = file.elements["File/track[@type='General']"]

      data = [
        file.elements["name"],
        file.elements["url"],
        general.elements["File_size"],
        general.elements["Duration"],
        general.elements["Format"]
      ]

      @media << Media.new( *data.map {|d| d ? d.text : d } )
    end
  end
end

