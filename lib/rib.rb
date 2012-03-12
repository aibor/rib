# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'
load File.expand_path('../html/html.rb', __FILE__)

module RIB
   
  class Configuration
    Conf = Struct.new(:irc, :nick, :channel, :auth, :tc, :qcmd, :qmsg, :linkdump, :dumplink, :helplink, :title, :pony, :verbose)

    def initialize( file )
      @config = default
      cfile = File.expand_path("../../#{file}", __FILE__)
      File.exist?(cfile) ? read(cfile) : puts("File doesn't exist: " + cfile)
    end

    def default # Default Configuration
      Conf.new(
        "irc.quakenet.org",                          # irc
        "rubybot" + rand(999).to_s,                  # nick
        "#rib",                                      # channel
        nil,                                         # auth
        "!",                                         # tc
        "quit",                                      # qcmd
        "Bye!",                                      # qmsg
        "./yaylinks",                                # linkdump
        "http://www.linkdumpioorrrr.de",             # dumplink
        "http://www.linkdumpioorrrr.de/rib-help",    # helplink
        true,                                        # title
        nil                                          # pony
      )                                         
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
    attr_accessor :trigger, :help, :commands

    def initialize( moduledir )
      @moddir = moduledir
      update
    end

    def update
      readmoduledir(@moddir)
      @trigger = getconstant("TRIGGER")
      @help = getconstant("HELP")
      setcommands
    end

    def readmoduledir( moduledir )
      mods = Dir.glob(moduledir + "/*.rib.rb")
      if ! mods.empty?
        mods.each {|mod| load mod}
      end
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
      @mods, @cmd, @source = mods, cmd, cmd.prefix.match(/\A(.*?)!/)[1]  
    end

    def check
      output = Array.new(2)
      @mods.trigger.each do |mod, trig|
        if @cmd.last_param =~ trig
          workmod = Class.new(eval("RIB::MyModules::" + mod.to_s)).new
          out = workmod.output(@source, $~)
          ObjectSpace.define_finalizer(self, proc { workmod.self_destruct! })
          output = out.is_a?(Array) ? out : [nil, out]
          break
        end
      end
      ObjectSpace.garbage_collect
      output[0] = @source if ! @cmd.params[0].include? "#" and output[0].nil?
      output[0] = RIB::CONFIG.channel if output[0].nil?
      output
    end
  end # class Message

end # module RIB
