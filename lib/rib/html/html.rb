module HTML
  require 'net/http'
  require 'uri'
  require File.expand_path('../entities.rb', __FILE__)

  def self.unentit( string, enc )
    string.encode!("utf-8", enc)
    string.gsub(/&(.*?);/) do
      ent = $1
      return nil if ent.nil?
      if ent =~ /\A#x([0-9a-f]+)\Z/i
        out = $1.hex
      elsif ent =~ /\A#0*(\d+)\Z/
        out = $1.to_i
      elsif ENTITIES.has_key?(ent)
        out = ENTITIES[ent]
      elsif ENTITIES.has_key?(ent.downcase)
        out = ENTITIES[ent.downcase]
      else
        return string
      end
      out.chr("utf-8")
    end
  end

  def self.fetch( url, limit )
    raise ArgumentError,'HTTP redirect too deep' if limit == 0
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host)
    resp = http.request_get(uri.request_uri) do |res|
      if res.content_type == 'text/html'
        res.read_body
      else
        res.instance_eval {@body_exist = false}
      end
    end # request_get
    raise ArgumentError, 'Redirect source and target identical' if url == resp['location']
    case resp
    when Net::HTTPRedirection then 
      fetch(resp['location'], limit - 1)
    when Net::HTTPSuccess then resp 
    when Net::HTTPClientError then resp
    else raise resp.error! #"HTTP-Header failure"
    end # case resp
  end

  def self.title( url )
    resp = fetch(url, 20)
    raise "No title can be found" if resp.nil?
    enc = "utf-8"
    enc = $1 if resp.body =~ /charset=([-\w]+)/
    resp.body =~ /\<title\>\s*([^<]*)\s*\<\/title\>/mi 
    raise "No title can be found" if $1.nil?
    unentit($1, enc).gsub(/(\r|\n)/, " ").gsub(/(\s{2,})/, " ")
  end
end
