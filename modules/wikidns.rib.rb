module RIB
  module MyModules
    class Wikidns
      require "resolv"

      TRIGGER = /\A#{RIB::TC}(?:wiki|w) (.+)\Z/
      
      # s = source of message, m = matchdata of TRIGGER-regexp
      def output( s, m )
        begin
          out = dnsrequest( m[1], ".wp.dg.cx").join('')
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

      def dnsrequest( string, domain )
        dns = Resolv::DNS.new(:nameserver => ['208.67.220.220','208.67.222.222','8.8.8.8'])
        req = dns.getresource( string + domain, Resolv::DNS::Resource::IN::TXT).strings
        req
      end
    end
  end
end
