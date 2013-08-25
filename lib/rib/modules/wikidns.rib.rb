# coding: utf-8
module RIB
  module MyModules
    class Wikidns < RIB::MyModulesBase
			# Great project by David Leadbeater. Get a short summary from Wikipedia
			# about a keyword over DNS. Description of the project: 
			# https://dgl.cx/2008/10/wikipedia-summary-dns
      require "resolv"

      def trigger
        /\A#{@bot.config.tc}(?:wiki|w) (.+)\Z/
      end
      
      # s = source of message, m = matchdata of TRIGGER-regexp
      def output( s, m, c )
        begin
          out = dnsrequest( m[1] + ".wp.dg.cx", %w(208.67.220.220 208.67.222.222 8.8.8.8)).join('')
        rescue Resolv::ResolvError
          out = "Nix gefunden. :/"
        end
        begin
          out =~ /.*?(http:\/\/(\S*)).*?/x
          raise if $1.nil?
          title = "\n" + Pagetitle.new.ftitle($1).to_s
        rescue
          title = nil
        end
        title = "" if title.nil?
        out << title 
        return nil, out
      end

      def dnsrequest(host, nameserver)
        dns = Resolv::DNS.new(nameserver: nameserver)
        dns.getresource(host, Resolv::DNS::Resource::IN::TXT).strings
      end
    end
  end
end
