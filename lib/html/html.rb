# coding: utf-8

require 'net/https'
require 'uri'
require 'html/entities.rb'


module HTML

  class Error < StandardError; end
  class NoPageFoundError < Error; end
  class NoTitleFoundError < Error; end


  module Regex
    Title   = /\<title[^>]*\>\s*([^<]*)\s*\<\/title\>/mi
    Charset = /charset="?(?:x-)?([-\w]+)/i
  end

  DefaultEncoding = Encoding.default_external


  module_function

  def unentit(string, enc = DefaultEncoding)
    string.encode!(DefaultEncoding, enc)
    string.gsub(/&(.*?);/) do
      if not ent = $1
        '&;'
      elsif ent =~ /\A#x([0-9a-f]+)\Z/i
        $1.hex.chr(DefaultEncoding)
      elsif ent =~ /\A#0*(\d+)\Z/
        $1.to_i.chr(DefaultEncoding)
      elsif Entities.has_key?(ent.downcase)
        Entities[ent.downcase].chr(DefaultEncoding)
      else
        "&#{ent};"
      end
    end
  end


  def fetch(url, limit = 10)
    raise ArgumentError,'HTTP redirect too deep' if limit == 0

    uri = URI.parse(url)

    opts = {
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }

    http = Net::HTTP.start(uri.host, uri.port, opts)

    resp = http.request_get(uri.request_uri) do |res|
      if res.content_type == 'text/html'
        res.read_body
      else
        res.instance_eval { @body_exist = false }
      end
    end # request_get

    case resp
    when Net::HTTPRedirection
      raise 'Redirection Loop' if url == resp['location']
      fetch(resp['location'], limit - 1)
    when Net::HTTPSuccess
      resp
    when Net::HTTPClientError
      resp
    else
      raise resp.error! #"HTTP-Header failure"
    end # case resp
  end


  def title(url)
    raise NoPageFoundError unless resp = fetch(url, 20)
    raise NoTitleFoundError unless title = resp.body[Regex::Title, 1]
    unentit(title, resp.body[Regex::Charset, 1]).split.join(' ')
  end

end

