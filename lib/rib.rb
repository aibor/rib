# coding: utf-8

require "net/http"
require "uri"
require "iconv" if RUBY_VERSION < '1.9'
load File.expand_path('../html/html.rb', __FILE__)

module RIB
   
  class Configuration
    Conf = Struct.new(:irc, :port, :use_ssl, :ssl_verify, :ssl_ca_path, :ssl_client_cert, :nick, :channel, :auth, :tc, :password, :qmsg, :linkdump, :dumplink, :helplink, :title, :pony, :verbose)

    def initialize( file )
      @config = default
      cfile = File.expand_path("../../#{file}", __FILE__)
      File.exist?(cfile) ? read(cfile) : puts("File doesn't exist: " + cfile)
    end

    def default # Default Configuration
      Conf.new(
        "irc.quakenet.org",                          # irc
				6667,																				 # port
				nil,																				 # use_ssl
				nil,																				 # ssl_verify
				"/etc/ssl/certs",														 # ssl_ca_path
				nil,																				 # ssl_client_cert
        "rubybot" + rand(999).to_s,                  # nick
        "#rib",                                      # channel
        nil,                                         # auth
        "!",                                         # tc
        "rib",                                       # password
        "Bye!",                                      # qmsg
        "./yaylinks",                                # linkdump
        "http://www.linkdumpioorrrr.de",             # dumplink
        "https://github.com/aibor/rib/wiki",		     # helplink
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
        if t.to_s =~ /\\A!\(?(?:\?\:)?(\w+(\|\w+|\s\w+)*)/
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
          out = workmod.output(@source, $~, @cmd)
          ObjectSpace.define_finalizer(self, proc { workmod.self_destruct! })
          output = out.is_a?(Array) ? out : [nil, out]
          break
        end
      end
      ObjectSpace.garbage_collect
			if output[0].nil?
				if @cmd.params[0].include? "#"  
					output[0] = @cmd.params[0]
				else
					output[0] = @source 
				end
      #output[0] = RIB::CONFIG.channel if output[0].nil?
			end
      output
    end
  end # class Message

end # module RIB
