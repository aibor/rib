# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'

def unentit( string, enc )
  require File.expand_path('../entities.rb', __FILE__)
  if RUBY_VERSION > '1.9'
    string.encode!("utf-8", enc)
  else
    string = Iconv.iconv("utf-8", enc, string).to_s
  end
  string.gsub(/&(.*?);/) do
    ent = $1
    return nil if ent.nil?
    if ent =~ /\A#x([0-9a-f]+)\Z/i
      out = $1.hex
    elsif ent =~ /\A#0*(\d+)\Z/
      out = $1.to_i
    elsif ENTITIES.has_key?(ent)
      out = ENTITIES[ent]
    else
      return "&#{ent};"
    end
    if RUBY_VERSION > '1.9'
      out.chr("utf-8")
    else
      out.chr
    end
  end
end

def fetch( url, limit )
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
  case resp
  when Net::HTTPRedirection then 
    fetch(resp['location'], limit - 1)
  when Net::HTTPSuccess then resp 
  else raise "HTTP-Header failure"
  end # case resp
end

def title( url )
  resp = fetch(url, 10)
  raise "No title can be found" if resp.nil?
  enc = "utf-8"
  enc = $1 if resp.body =~ /charset=([-\w\d]+)/
  resp.body =~ /\<title\>\s*([^<]*)\s*\<\/title\>/mi 
  raise "No title can be found" if $1.nil?
  title = unentit($1, enc).gsub(/(\r|\n)/, " ").gsub(/(\s{2,})/, " ")
  case title 
  when /(\s+- YouTube\s*\Z)/ then return "1,0You0,4Tube #{title.sub(/#{$1}/, "")}"
  when /(\Axkcd:\s)/ then return "xkcd: #{title.sub(/#{$1}/, "")}"
  when /(\son\sdeviantART\Z)/ then return "0,10deviantART #{title.sub(/#{$1}/, "")}"
  else return "Title: #{title}"
  end # case title
end

def gsearch( key )
  if RUBY_VERSION > '1.9'
    key.encode!("utf-8", "iso-8859-1") if key.encoding.name != "UTF-8"
  else
    key = Iconv.iconv("utf-8", "iso-8859-1", key).to_s
  end
  resp = fetch(URI.escape("http://www.google.com/search?hl=de&q=#{key.gsub(/\s/, "+")}&ie=utf-8&oe=utf-8"), 10)
  raise "Nothing found with gsearch()" if resp.nil?
  resp.body =~ /<li class=g[>|\s].*?<a href="(.*?)"/
  output = $1
end

def floodprot
  raise "flood protection" if ! @last.nil? and ( Time.new.to_i < (@last + 20).to_i )
  @last = Time.new.to_i
end

def trigger( arg, conf, server, log = nil )
  case arg
  when /\Ahelp/ then
    floodprot
    output = 
    "\"#{conf["tc"]}g SUCH\"     sucht bei Google danach\n" <<
    "\"#{conf["tc"]}most\"     zeigt die #{conf["most"]} häufigsten Wörter\n" <<
    "\"#{conf["tc"]}stats USER\"     Statistiken zu diesem Benutzer\n" <<
    "\"#{conf["tc"]}set title=0/1\"     HTML-Titel verbergen/anzeigen\n" <<
    "\"#{conf["tc"]}set pony=0/1\"     Ponyliebe verbergen/zeigen"

  when /\A#{conf["qcmd"]}/ then 
    server.quit("[#{conf["qmsg"]}]")
    log.info("Server left") if ! log.nil?

  when /\A#{conf["nick"]}say (.*)\Z/ then output = $1

  when /\Aset (title|pony)=([0-1])/ then 
    conf[$1] = ! $2.to_i.zero?
    output = $1 + " = " + $2
    log.info("Configuration set: #{$1} = #{conf[$1]}") if ! log.nil?

  when /\Amost\s*(\d*)/ then 
    most = $Stats.most(conf["most"], $1.to_i)
    raise if most.nil?
    floodprot
    output = "Die #{conf["most"]} meistbenutzen Wörter seit dem #{most[0]}:\n" 
    i = 1
    most[1..conf["most"]].each do |c|
      output << i.to_s << ".:\t\t" << c[1].to_s << "x\t\t" << c[0] << "\n"
      i += 1
    end

  when /\Astats (\w*)/ then 
    stats = $Stats.user($1)
    raise if stats.nil?
    output = "#{$1} kam seit dem #{stats[0]} bisher #{stats[1]} mal zu Wort und füllte das Log mit #{stats[2]} zusätzlichen Wörtern."

  when /\Ag (.*)\Z/ then 
    output = gsearch($1)
    output << "\n" << title(output)

  when /\A(\S*)/ then output = conf["resp"][$1][rand(conf["resp"][$1].length)] if conf["resp"].has_key?($1)

  else output = nil
  end # case
  return output
end

def readconf(cfile)
  cfile = File.expand_path("../../#{cfile}", __FILE__)
  conf = Hash.new
  conf["resp"] = Hash.new
  if File.exist?(cfile)
    file = File.open(cfile, File::RDONLY | File::NONBLOCK)
    file.each do |line|
      line =~ /\A\s*(\w+)\s*(=\s*(.*?)\s*)?\Z/
      key, val = $1, $3
      next if key == "#" || key.nil?
      if $2.nil?
        conf[key] = true
        next
      end
      if key == "most"
        val = val.to_i
        val = 7 if val > 7
        conf[key] = val
        next 
      end
      if val.include? '"'
        val = val.scan(/".*?"/)
        val.each {|v| v.gsub!(/\A"(.*)"\Z/, '\1')}
        val = val[0] if val.length == 1
      end
      if key == "resp"
        conf[key][val.shift] = val
        next
      end
      conf[key] = val
    end
  end
  conf
end

