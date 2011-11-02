# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'
load File.expand_path('../html/html.rb', __FILE__)

def ftitle( url )
  title = HTML.title(url)
  return nil if title.empty?
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
  uri = URI.parse(URI.escape("https://www.google.com/search?hl=de&btnI=1&q=#{key.gsub(/\s/, "+")}&ie=utf-8&oe=utf-8&pws=0"))
  http = Net::HTTP.new(uri.host)
  resp = http.request_head(uri.request_uri)
  resp['location']
end

def floodprot(int)
  int = 15 if ! int.is_a?(Fixnum)
  raise "flood protection" if ! @last.nil? and ( Time.new.to_i < (@last + int).to_i )
  @last = Time.new.to_i
end

def timediff( start )
  raise if ! start.is_a?(Time)
  diff = (Time.now - start).to_i
  s = diff.modulo(60)
  m = diff.modulo(3600)/60
  h = diff.modulo(3600*24)/3600
  d = diff/(3600*24)

  uptime = String.new
  uptime << d.to_s + "d " if d > 0
  uptime << h.to_s + "h " if h > 0
  uptime << m.to_s + "m " if m > 0
  uptime << s.to_s + "s"
end

def trigger( arg, conf, server, source, log = nil )
  target = nil
  case arg
  when /\Ahelp(\sme)?/i then
    floodprot(10)
    return output = "Kein Link angegeben. :/" if conf["helplink"].nil? or conf["helplink"].empty?
    title = ftitle(conf["helplink"]).to_s
    output = conf["helplink"] + "\n" + title
    target = source if ! $1.nil?
    #output = 
    #"#{conf["tc"]}add URL       speichere URL\n" <<
    #"#{conf["tc"]}give          gib link zum linkdump aus\n" <<
    #"#{conf["tc"]}g SUCH        sucht bei Google danach\n" <<
    #"#{conf["tc"]}most          zeigt die #{conf["most"]} häufigsten Wörter\n" <<
    #"#{conf["tc"]}stats USER     Statistiken zu diesem Benutzer\n" <<
    #"#{conf["tc"]}set title=0/1     HTML-Titel verbergen/anzeigen\n" <<
    #"#{conf["tc"]}set pony=0/1     Ponyliebe verbergen/zeigen\n" <<
    #"#{conf["tc"]}uptime            zeigt an, wie lange der Bot schon läuft"

  when /\Aadd\s+(http[s]?:\/\/(\S*))/xi then
    return [target, nil] if ! conf.has_key?("linkdump") or conf["linkdump"].empty?
    linkdump = File.expand_path("../../"+conf["linkdump"], __FILE__)
    #raise "linkdump not writeable" if File.stat(linkdump).writable_real?
    lines = String.new
    lines = "--------------------\n" if File.exist?(linkdump)
    lines << Time.now.asctime << " - " << source << "\n" << $1 << "\n"
    File.open(linkdump, File::WRONLY | File::APPEND | File::CREAT) {|f| f.write(lines) }
    title = ftitle($1).to_s
    output = title + "\nLink added!"
   
  when /\Adel\s+(\d+)/ then
    num = $1.to_i
    return [target, "Nein!"] if ! conf.has_key?("linkdump") or conf["linkdump"].empty? or num < 1
    linkdump = File.expand_path("../../"+conf["linkdump"], __FILE__)
    File.unlink(linkdump) if File.exist?(linkdump)
    entrydir = File.dirname(linkdump)+"/entries/"
    entryarr = Dir.entries(entrydir).sort.delete_if {|e| e =~ /\A\./}
    entry = entryarr[(num - 1)] 
    return [target, "Eintrag ##{num} nicht gefunden"] if entry.nil?
    entry =~ /\A\d+-(.*?)\Z/
    return [target, "Du nicht!"] if $1 != source
    File.unlink(entrydir+entry)
    output = "Eintrag ##{num} gelöscht"

  when /\Agive/i then 
    return [target, "Kein Link angegeben. :/"] if conf["dumplink"].nil? or conf["dumplink"].empty?
    title = ftitle(conf["dumplink"]).to_s
    output = conf["dumplink"] + "\n" + title

  when /\Auptime/i then
    output = "Uptime:\t" + timediff($Starttime)

  when /\A#{conf["qcmd"]}/ then 
    server.quit("[#{conf["qmsg"]}]")
    log.info("Server left") if ! log.nil?

  when /\A#{conf["nick"]}say (.*)\Z/ then output = $1

  when /\Aset (title|pony)=([0-1])/i then 
    conf[$1] = ! $2.to_i.zero?
    output = $1 + " = " + $2
    log.info("Configuration set: #{$1} = #{conf[$1]}") if ! log.nil?

  when /\Amost\s*(\d*)/i then 
    most = $Stats.most(conf["most"], $1.to_i)
    raise if most.nil?
    floodprot(11)
    output = "Die #{conf["most"]} meistbenutzen Wörter seit dem #{most[0]}:\n" 
    i = 1
    most[1..conf["most"]].each do |c|
      output << i.to_s << ".:\t\t" << c[1].to_s << "x\t\t" << c[0] << "\n"
      i += 1
    end

  when /\Astats (\w*)/i then 
    stats = $Stats.user($1)
    raise if stats.nil?
    output = "#{$1} kam seit dem #{stats[0]} bisher #{stats[1]} mal zu Wort und füllte das Log mit #{stats[2]} zusätzlichen Wörtern."

  when /\Ag (.*)\Z/i then 
    output = gsearch($1)
    return [target, nil] if output.nil?
    output << "\n" << ftitle(output).to_s

  when /\A(\S*)/ then output = conf["resp"][$1][rand(conf["resp"][$1].length)] if conf["resp"].has_key?($1)

  else output = nil
  end # case
  return [target, output]
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

