# coding: utf-8

module RIB
  module MyModules
    class Pagetitle
      TRIGGER = /\A(?!#{RIB::TC}).*?(http[s]?:\/\/\S*)/x
      
      def output( s, m, c )
        if CONFIG.title
          return nil, ftitle(m[1])
        end
      end

      def ftitle( url )
        require 'html/html'
        title = HTML.title(url)
        return nil if title.empty?
        load File.expand_path('../../lib/formattitle.rb', __FILE__)
        formattitle(title)
      end
    end
    class Settitle
      TRIGGER = /\A#{RIB::TC}set title\s*=?\s*(on|off|0|1)/i
      HELP = "De-/aktiviere die automatische HTML-Titelausgabe für URLS. -- #{RIB::TC}set title <0|1|on|off>"

      def output( s, m, c )
        case m[1]
        when /on|1/ then 
          CONFIG.title(true)
          out = "title turned on"
        when /off|0/ then 
          CONFIG.title(nil)
          out = "title turned off"
        else out = "Usage: #{RIB::TC}set title [on|off|1|0]"
        end
        return nil, out
      end
    end
  end
end
