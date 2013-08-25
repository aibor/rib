# coding: utf-8
module RIB
  module MyModules
    class Pony < RIB::MyModulesBase
      def trigger
        /\A(?!#{@bot.config.tc}).*?([p][o][n]{1,2}[yi][e]?s*)/i
      end

      def output( s, m, c )
        if @bot.config.pony and rand(2).zero?
          return nil, m[1] + " yay." 
        end
      end
    end

    class Setpony < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}set pony\s*=?\s*(on|off|0|1)/i
      end
      def help
        "#{@bot.config.tc}set pony <0|1|on|off> -- De-/aktiviere die automatische Ponyliebe."
      end

      def output( s, m, c )
        case m[1]
        when /on|1/ then 
          @bot.config.pony(true)
          out = "ponies yay."
        when /off|0/ then 
          @bot.config.pony(nil)
          out = "aaawwwwwwwww *sadface*"
        else out = "Usage: #{@bot.config.tc}set pony [on|off|1|0]"
        end
        return nil, out
      end
    end
  end
end
