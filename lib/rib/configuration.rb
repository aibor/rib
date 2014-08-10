# coding: utf-8

module RIB

  class Configuration
    SSL = Struct.new(:use, :verify, :ca_path, :client_cert)


    def initialize
      @config = default
    end


    def method_missing( meth, *args )
      meth = meth.to_s.sub(/=$/, '').to_sym

      insert(meth, args.shift) unless args.empty?
      if @config.has_key? meth 
        @config[meth] 
      else
        super 
      end
    end


    def defined?( key )
      (@config.has_key?(key.to_sym) && ! @config[key.to_sym].nil?)
    end


    private

    def default # Default Configuration
      {
        protocol:   :irc,
        server:     'irc.quakenet.org',
        port:       6667,
        ssl:        SSL.new( false, false, '/etc/ssl/certs', '' ),
        nick:       'rib' + rand(999).to_s,
        jid:        'rubybot@xmpp.example.com',
        channel:    '#rib',
        tc:         '!',
        password:   'rib',
        qmsg:       'Bye!',
        title:      true,
        pony:       false,
        logdir:     'log/',
        debug:      false,
        modules:     []
      }
    end


    def insert( key, val )
      @config[key.to_sym] = val
    end
  end
end
