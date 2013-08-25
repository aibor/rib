# coding: utf-8
module RIB
  module MyModules

    class Pagetitle < RIB::MyModulesBase
      def trigger
        /\A(?!#{@bot.config.tc}).*?(http[s]?:\/\/\S*)/x
      end
      
      def output( s, m, c )
        if @bot.config.title
          return nil, Pagetitle.ftitle(m[1])
        end
      end

      def self.ftitle( url )
        require 'rib/html/html'
        title = HTML.title(url)
        return nil if title.empty?
        load File.expand_path('../../formattitle.rb', __FILE__)
        formattitle(title)
      end
    end
    class Settitle < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}set title\s*=?\s*(on|off|0|1)/i
      end
      def help
        "De-/aktiviere die automatische HTML-Titelausgabe für URLS. -- #{@bot.config.tc}set title <0|1|on|off>"
      end

      def output( s, m, c )
        case m[1]
        when /on|1/ then 
          @bot.config.title(true)
          out = "title turned on"
        when /off|0/ then 
          @bot.config.title(nil)
          out = "title turned off"
        else out = "Usage: #{@bot.config.tc}set title [on|off|1|0]"
        end
        return nil, out
      end
    end
  end
end
