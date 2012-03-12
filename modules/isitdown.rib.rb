# coding: utf-8
module RIB
  module MyModules
    class Isitdown
      TRIGGER = /\A#{RIB::TC}isup\s+([\w.]+)/xi
      HELP = "#{RIB::TC}isup rigged.me -- Test a Host if it's up or not."

      #require 'html/html'
      
      def isupme(host)
        url = "http://www.isup.me/" + host 
        HTML.fetch(url, 7).body =~ /<body>.*?<div id="container">(.*?)<a.*?>(.*?)<\/a>(?:<\/span>)?(.*?)<p><a/mi
        out = $1 + $2 + $3
        out.gsub(/\n/,'').strip.gsub(/\s{2,}/,' ')
      end

      def botserver(host)
        url = "http://" + host
        answer = 
          begin
            HTML.fetch(url, 10).code.to_i < 400
          rescue ArgumentError
            false
          end
        if answer
          host + " ist von hier aus erreichbar."
        else
          host + " ist für mich nicht erreichbar. :/"
        end
      end

      # s = source of message, m = matchdata of TRIGGER-regexp
      def output( s, m )
        out = s + ": " + isupme(m[1])
        #out = s + ": " + botserver(m[1])
        return nil, out
      end

    end
  end
end
