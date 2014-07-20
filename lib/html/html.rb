module HTML
  require 'net/https'
  require 'uri'
  require 'html/entities.rb'

  TitleRegex = /\<title\>\s*([^<]*)\s*\<\/title\>/mi 

  def self.unentit( string, enc )
    string.encode!("utf-8", enc)
    string.gsub(/&(.*?);/) do
      ent = $1
      return nil if ent.nil?
      if ent =~ /\A#x([0-9a-f]+)\Z/i
        out = $1.hex
      elsif ent =~ /\A#0*(\d+)\Z/
        out = $1.to_i
      elsif HTML::ENTITIES.has_key?(ent)
        out = HTML::ENTITIES[ent]
      elsif HTML::ENTITIES.has_key?(ent.downcase)
        out = HTML::ENTITIES[ent.downcase]
      else
        return string
      end
      out.chr("utf-8")
    end
  end

  def self.fetch( url, limit )
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
        res.instance_eval {@body_exist = false}
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

  def self.title( url )
    raise "No page found" unless resp = fetch(url, 20)
    enc = resp.body =~ /charset=([-\w]+)/ ? $1 : 'utf-8'
    raise "No title found" unless resp.body =~ TitleRegex
    unentit($1, enc).gsub(/(\r|\n)/, " ").gsub(/(\s{2,})/, " ")
  end
end
