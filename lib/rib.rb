# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'
load File.expand_path('../html/html.rb', __FILE__)

def ftitle( url )
  title = HTML.title(url)
  return nil if title.empty?
  load File.expand_path('../formattitle.rb', __FILE__)
  formattitle(title)
end

def gsearch( site, key )
  if RUBY_VERSION > '1.9'
    key.encode!("utf-8", "iso-8859-1") if key.encoding.name != "UTF-8"
  else
    key = Iconv.iconv("utf-8", "iso-8859-1", key).to_s
  end
  key.gsub!(/\s/, "+")
  case site
    when /w(iki)?/ then url = "https://www.google.com/search?hl=de&btnI=1&q=site:wikipedia.org+#{key}&ie=utf-8&oe=utf-8&pws=0" 
    when /d(ict)?/ then url = "http://dict.cc/?s=#{key}"
    else url = "https://www.google.com/search?hl=de&btnI=1&q=#{key}&ie=utf-8&oe=utf-8&pws=0" 
  end
  count = 10
  while ! url.nil?
    out = url
    uri = URI.parse(URI.escape(url))
    http = Net::HTTP.new(uri.host)
    resp = http.request_head(uri.request_uri)
    break if url == resp['location']
    url = resp['location']
    count.zero? ? break : (count = count - 1) 
  end
  out
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

def getentryname( path, num )
  entrydir = File.dirname(path)+"/entries/"
  entryarr = Dir.entries(entrydir).sort.delete_if {|e| e =~ /\A\./}
  entrycnt = entryarr.size
  case  num
  when "r" then num = rand(entryarr.length)
  when "l" then num = -1
  else 
    if num < 0
      num += entrycnt
    else
      num -= 1 
    end
  end
  raise if num < -1
  entryarr[(num)] =~ /\A(\d+)-(.*?)-(.*?)\Z/
  [entrydir, $&, $1, $2, $3]
end

def readentry(file)
  f = File.open(file, File::RDONLY | File::NONBLOCK) 
  line = f.gets
  line =~ /\A<a href="(.*?)" target="_blank" title="(.*?)">(?:.*?)<\/a><br>\Z/
  title = $2.empty? ? $2 : formattitle(HTML.unentit($2, "utf-8"))
  $1 + "\n" + title
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

  when /\Aadd\s+(http[s]?:\/\/(\S*))/xi then
    return [target, nil] if ! conf.has_key?("linkdump") or conf["linkdump"].empty?
    linkdump = File.expand_path("../../"+conf["linkdump"], __FILE__)
    lines = String.new
    lines = "--------------------\n" if File.exist?(linkdump)
    lines << Time.now.asctime << " - " << source << " - " << server.whois(source).auth << "\n" << $1 << "\n"
    File.open(linkdump, File::WRONLY | File::APPEND | File::CREAT) {|f| f.write(lines) }
    updatefile = File.dirname(linkdump)+"/entries/.lastupdate"
    File.unlink(updatefile) if File.exist?(updatefile)
    ftitle(conf["dumplink"])
    begin
      title = ftitle($1).to_s + "\n"
    rescue
      title = nil
    end
    title = "" if title.nil?
    output = title + "Link added!"
   
  when /\Adel\s+(\d+)/ then
    num = $1.to_i
    return [target, "Nein!"] if ! conf.has_key?("linkdump") or conf["linkdump"].empty? or num < 1
    linkdump = File.expand_path("../../"+conf["linkdump"], __FILE__)
    File.unlink(linkdump) if File.exist?(linkdump)
    entry = getentryname(linkdump, num)
    return [target, "Eintrag ##{num} nicht gefunden"] if entry[1].nil?
    return [target, "Du nicht!"] if entry[4] != server.whois(source).auth
    File.unlink(entry[0]+entry[1])
    output = "Eintrag ##{num} gelöscht"

  when /\Agive\s*(l|r|\d*)/i then 
    input = ($1 or 0)
    if input =~ /\A[l|r]\Z/
      num = input
    else
      num = input.to_i 
    end
    return [target, "Kein Link angegeben. :/"] if conf["dumplink"].nil? or conf["dumplink"].empty?
    begin
      raise if num =~ /[^lr]/
      raise if num.respond_to?("zero?") and num.zero?
      linkdump = File.expand_path("../../"+conf["linkdump"], __FILE__)
      entry = getentryname(linkdump, num)
      file = entry[0]+entry[1]
      raise if ! File.exist?(file)
      output = readentry(file)
    rescue
      url = conf["dumplink"]
      title = ftitle(url).to_s
      output = url + "\n" + title
    end

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

  when /\A(g|w|d|wiki|dict) (.*)\Z/i then 
    site = $1
    key = $2.to_s
    output = gsearch(site, key)
    return [target, nil] if output.nil?
    begin
      title = "\n" + ftitle(output).to_s
    rescue
      title = nil
    end
    title = "" if title.nil?
    output << title 

  when /\A(\S*)/ then output = conf["resp"][$1][rand(conf["resp"][$1].length)] if conf["resp"].has_key?($1)

  else output = nil
  end # case
  return [target, output]
end


module RIB
  Conf = Struct.new(:irc, :nick, :channel, :auth, :tc, :qcmd, :qmsg, :linkdump, :dumplink, :helplink, :title, :pony)
  # Default Configuration
  DEFCONFIG = Conf.new("irc.quakenet.org",                        # irc
                     "rubybot" + rand(999).to_s,                  # nick
                     "#rubybot",                                  # channel
                     nil,                                         # auth
                     "!",                                         # tc
                     "quit",                                      # qcmd
                     "Bye!",                                      # qmsg
                     "./yaylinks",                                # linkdump
                     "http://www.linkdumpioorrrr.de",             # dumplink
                     "http://www.linkdumpioorrrr.de/rib-help",    # helplink
                     true,                                        # title
                     nil)                                         # pony
  
  class Configuration

    def initialize( file )
      @config = DEFCONFIG
      cfile = File.expand_path("../../#{file}", __FILE__)
      if File.exist?(cfile)
        if read(cfile).nil?
        else
          puts "Can not read file: " + cfile
        end
      else
        puts "File doesn't exist: " + cfile
      end
    end

    def read(cfile)
      file = File.open(cfile, File::RDONLY | File::NONBLOCK)
      file.each do |line|
        line =~ /\A\s*(#?)\s*(\w+)\s*(=\s*"?(.*?)"?\s*)?\Z/
        key, val = $2, $4
        next if $1 == "#" or key.nil?
        val = true if $3.nil?
        insert(key, val)
      end
      file.close
    end

    def update( file )
      read( file )
    end

    def method_missing( meth, *args )
      if @config.members.include? meth
        args.empty? ? @config[meth] : insert(meth, args.shift)
      elsif @config[arg[0]]
        super
      end
    end

    def insert( key, val )
      @config[key.to_sym] = val if @config.respond_to?(key)
    end

  end # class Config

  # initialize configuration from file
  CONFIG = Configuration.new("config")
  TC = CONFIG.tc

  # Modulklasse
  class Modules 
    def initialize( moduledir )
      readmoduledir(moduledir)
      settrigger
    end

    def readmoduledir( moduledir )
      mods = Dir.glob(moduledir + "/*.rib.rb")
      if ! mods.empty?
        mods.each {|mod| loadmod(mod)}
      end
    end

    def loadmod( modpath )
      require modpath
    end

    def trigger
      @trigger
    end

    def settrigger
      @trigger = Hash.new
      RIB::MyModules.constants.each do |mymod|
        name = "RIB::MyModules::" + mymod.to_s
        next if ! (eval(name + ".respond_to?('new')"))
        cmd = name + ".const_get('TRIGGER')"
        @trigger[mymod] = (eval cmd)
      end
    end

  end # class Modules

  MODS = RIB::Modules.new(File.expand_path('../rib/modules/', __FILE__))

  # Klasse, die eingehende PRIVMSG auf trigger prüft
  class Message
    def initialize( cmd )
      @cmd = cmd
      @output = Array.new(2)
      cmd.prefix.match(/\A(.*?)!/)  
      @source = $1 if ! $1.nil?
    end

    def check
      RIB::MODS.trigger.each do |mod, trig|
        if @cmd.last_param =~ trig
          cmd = "RIB::MyModules::" + mod.to_s + ".new.output(@source, $~)"
          out = eval(cmd)
          @output = out.is_a?(Array) ? out : @output
          break
        end
      end
      @output
    end
  end # class Message

end # module RIB
