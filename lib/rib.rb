# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'
load File.expand_path('../html/html.rb', __FILE__)

module RIB
  Conf = Struct.new(:irc, :nick, :channel, :auth, :tc, :qcmd, :qmsg, :linkdump, :dumplink, :helplink, :title, :pony, :verbose)
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
      meth = meth.to_s if RUBY_VERSION < '1.9'
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

    def commands
      setcommands
      @commands
    end

    def setcommands
      @commands = Array.new
      @trigger.each_value do |t|
        if t.to_s =~ /\\A!\(?(\w+(\|\w+|\s\w+)*)/
          $1.split(/\|/).each {|r| @commands.push(r)}
        end
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
