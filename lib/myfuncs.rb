# coding: utf-8

require "cgi"
require "net/http"
require "uri"

# Unescape a string that has been HTML-escaped
#   CGI::unescapeHTML("Usage: foo &quot;bar&quot; &lt;baz&gt;")
#      # => "Usage: foo \"bar\" <baz>"
def CGI::unescapeHTML(string)
  enc = string.encoding
  if [Encoding::UTF_16BE, Encoding::UTF_16LE, Encoding::UTF_32BE, Encoding::UTF_32LE].include?(enc)
    return string.gsub(Regexp.new('/&(amp|quot|gt|lt|euro|copy|[lr]aquo|reg|sup[2-3]|[aou]uml|szlig|oslash|#[0-9]+|#x[0-9A-Fa-f]+);/i'.encode(enc))) do
      case $1.encode("US-ASCII")
      when /amp/i                 then '&'.encode(enc)
      when /quot/i                then '"'.encode(enc)
      when /gt/i                  then '>'.encode(enc)
      when /lt/i                  then '<'.encode(enc)
      when /euro/i                then '€'.encode(enc)
      when /copy/i                then '©'.encode(enc)
      when /laquo/i               then '«'.encode(enc)
      when /raquo/i               then '»'.encode(enc)
      when /reg/i                 then '®'.encode(enc)
      when /sup2/i                then '²'.encode(enc)
      when /sup3/i                then '³'.encode(enc)
      when /a[uU][mM][lL]/        then 'ä'.encode(enc)
      when /o[uU][mM][lL]/        then 'ö'.encode(enc)
      when /u[uU][mM][lL]/        then 'ü'.encode(enc)
      when /A[uU][mM][lL]/        then 'Ä'.encode(enc)
      when /O[uU][mM][lL]/        then 'Ö'.encode(enc)
      when /U[uU][mM][lL]/        then 'Ü'.encode(enc)
      when /szlig/i               then 'ß'.encode(enc)
      when /oslash/i              then 'ø'.encode(enc)
      when /\A#0*(\d+)\z/        then $1.to_i.chr(enc)
      when /\A#x([0-9a-f]+)\z/i  then $1.hex.chr(enc)
      end
    end
  end
  asciicompat = Encoding.compatible?(string, "a")
  string.gsub(/&(amp|quot|gt|lt|euro|copy|[lr]aquo|reg|sup[2-3]|[aou]uml|szlig|oslash|\#[0-9]+|\#x[0-9A-Fa-f]+);/i) do
    match = $1.dup
    case match
    when /amp/i                 then '&'
    when /quot/i                then '"'
    when /gt/i                  then '>'
    when /lt/i                  then '<'
    when /euro/i                then '€'
    when /copy/i                then '©'
    when /laquo/i               then '«'
    when /raquo/i               then '»'
    when /reg/i                 then '®'
    when /sup2/i                then '²'
    when /sup3/i                then '³'
    when /a[uU][mM][lL]/        then 'ä'
    when /o[uU][mM][lL]/        then 'ö'
    when /u[uU][mM][lL]/        then 'ü'
    when /A[uU][mM][lL]/        then 'Ä'
    when /O[uU][mM][lL]/        then 'Ö'
    when /U[uU][mM][lL]/        then 'Ü'
    when /szlig/i               then 'ß'
    when /oslash/i              then 'ø'
    when /\A#0*(\d+)\z/
      n = $1.to_i
      if enc == Encoding::UTF_8 or
        enc == Encoding::ISO_8859_1 && n < 256 or
        asciicompat && n < 128
        n.chr(enc)
      else
        "&##{$1};"
      end
    when /\A#x([0-9a-f]+)\z/i
      n = $1.hex
      if enc == Encoding::UTF_8 or
        enc == Encoding::ISO_8859_1 && n < 256 or
        asciicompat && n < 128
        n.chr(enc)
      else
        "&#x#{$1};"
      end
    else
      "&#{match};"
    end
  end
end

def fetch(url, log = nil, limit = 10)
  raise ArgumentError,'HTTP redirect too deep' if limit == 0
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host)
  resp = http.request_get(uri.request_uri) do |res|
    if res.content_type == 'text/html'
      res.read_body
    else
      res.instance_eval {@body_exist = false}
    end
  end
  case resp
  when Net::HTTPRedirection then 
    fetch(resp['location'], log, limit - 1)
  when Net::HTTPSuccess then resp 
  else raise "Header failure"
  end # case resp
rescue 
  if ! log.nil?
    log.error("fetch()")
    log.error($!)
  end
  return nil
end

def title(url, log = nil)
  resp = fetch(url, nil, log)
  raise "No title can be found" if resp.nil?
  resp.body =~ /\<title\>\s*([^<]*)\s*\<\/title\>/mi 
  title = CGI::unescapeHTML($1).gsub(/(&#x202a;|&#x202c;&rlm;.*|)/, '').gsub(/(\r|\n)/, " ").gsub(/(\s{2,})/, " ")
  case title 
  when /(\s+- YouTube\s*\Z)/ then return "1,0You0,4Tube #{title.sub(/#{$1}/, "")}"
  when /(\Axkcd:\s)/ then return "xkcd: #{title.sub(/#{$1}/, "")}"
  when /(\son\sdeviantART\Z)/ then return "0,10deviantART #{title.sub(/#{$1}/, "")}"
  else return "Title: #{title}"
  end # case title
rescue 
  if ! log.nil?
    log.error("title()")
    log.error($!)
  end
  return nil
end

def gsearch( key, log = nil )
  key.encode!("utf-8", "iso-8859-1")
  resp = fetch(URI.escape("http://www.google.com/search?hl=de&q=#{key.gsub(/\s/, "+")}&ie=utf-8&oe=utf-8"), nil, log)
  raise "Nothing found" if resp.nil?
  resp.body =~ /<li class=g.*?<a href="(.*?)"/
  output = $1
rescue
  if ! log.nil?
    log.error("gsearch()")
    log.error($!)
  end
  return nil
end

def trigger( arg, conf, server, log = nil)
  case arg
  when /\Ahelp/ then
    output ="\"#{conf["tc"]}g SUCHE DAS\" sucht bei Google danach.\n\"#{conf["tc"]}most\" zeigt die #{conf["most"]} meistbenutzten Wörter an.\n\"#{conf["tc"]}stats BENUTZERNAME\" für Statistiken zu diesem Benutzer.\n\"#{conf["tc"]}set title=0/1\" um Anzeige der HTML-Titel aus/an zu schalten.\n\"#{conf["tc"]}set pony=0/1\" um Ponyliebe zu verbergen/zeigen."

  when /\A#{conf["qcmd"]}/ then 
    server.quit("[#{conf["qmsg"]}]")
    log.info("Server left") if ! log.nil?

  when /\A#{conf["nick"]}say (.*)\Z/ then output = $1

  when /\Aset (title|pony)=([0-1])/ then 
    conf[$1] = ! $2.to_i.zero?
    output = $1+" = "+$2
    log.info("Configuration set: #{$1} = #{conf[$1]}") if ! log.nil?

  when /\Amost/ then 
    most = $Stats.most(conf["most"])
    exit if most.nil?
    output = "Die #{conf["most"]} meistbenutzen Wörter seit dem #{most[0]}:\n" 
    i = 1
    most[1..conf["most"]].each {|c| output << i.to_s << ".:\t\t" << c[1].to_s << "x\t\t" << c[0] << "\n"; i += 1}

  when /\Astats (\w*)/ then 
    stats = $Stats.user($1)
    if ! stats.nil?
      output = "#{$1} kam seit dem #{stats[0]} bisher #{stats[1]} mal zu Wort und füllte das Log mit #{stats[2]} zusätzlichen Wörtern."
    end

  when /\Ag (.*)\Z/ then 
    output = gsearch($1, log)
    output << "\n" << title(output, log)

  when /\A(\S*)/ then output = conf["resp"][$1].sample if conf["resp"].has_key?($1)
  else output = nil
  end # case
  return output
rescue
  return nil
end

def readconf(cfile)
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
        conf[key] = val.to_i
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

