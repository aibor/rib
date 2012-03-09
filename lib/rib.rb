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

  # Modulklasse
  class Modules 
    def initialize( moduledir )
      @moddir = moduledir
      update
    end

    def update
      readmoduledir(@moddir)
      settrigger
      sethelp
      setcommands
    end

    def readmoduledir( moduledir )
      mods = Dir.glob(moduledir + "/*.rib.rb")
      if ! mods.empty?
        mods.each {|mod| loadmod(mod)}
      end
    end

    def loadmod( modpath )
      load modpath
    end

    def trigger
      @trigger
    end

    def settrigger
      @trigger = getconstant("TRIGGER")
    end

    def help
      @help
    end

    def sethelp
      @help = getconstant("HELP")
    end

    def getconstant( constantname )
      constant = Hash.new
      RIB::MyModules.constants.each do |mymod|
        name = "RIB::MyModules::" + mymod.to_s
        next if ! (eval(name + ".respond_to?('new')")) or ! eval(name + ".const_defined?('#{constantname}')")
        cmd = name + ".const_get('#{constantname}')"
        constant[mymod] = (eval cmd)
      end
      constant
    end

    def commands
      @commands
    end

    def setcommands
      @commands = Hash.new
      @trigger.each_pair do |k, t|
        if t.to_s =~ /\\A!\(?(\w+(\|\w+|\s\w+)*)/
          @commands[k] = Array.new
          $1.split(/\|/).each {|r| @commands[k].push(r)}
        end
      end
    end

  end # class Modules

  # Klasse, die eingehende PRIVMSG auf trigger prüft
  class Message
    def initialize( mods, cmd )
      @mods = mods
      @cmd = cmd
      @output = Array.new(2)
      cmd.prefix.match(/\A(.*?)!/)  
      @source = $1
    end

    def check
      @mods.trigger.each do |mod, trig|
        if @cmd.last_param =~ trig
          classname = "RIB::MyModules::" + mod.to_s 
          workmod = Class.new(eval classname).new
          out = workmod.output(@source, $~)
          ObjectSpace.define_finalizer(self, proc { workmod.self_destruct! })
          @output = out.is_a?(Array) ? out : @output
          break
        end
      end
      ObjectSpace.garbage_collect
      @output[0] = @source if ! @cmd.params[0].include? "#" and @output[0].nil?
      @output[0] = RIB::CONFIG.channel if @output[0].nil?
      @output
    end
  end # class Message

end # module RIB
