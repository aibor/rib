module RIB
  module MyModules
    class Pony
      TRIGGER = /\A[^#{RIB::TC}].*?([p][o][n]{1,2}[yi][e]?s*)/i
      def output( s, m )
        return m[1] + " yay." if CONFIG.pony == true && rand(2).zero?
      end
    end
    class Setpony
      TRIGGER = /\A#{RIB::TC}set pony\s*=?\s*(on|off|0|1)/i

      def output( s, m )
        case m[1]
        when /on|1/ then 
          CONFIG.pony(true)
          out = "ponies yay."
        when /off|0/ then 
          CONFIG.pony(nil)
          out = "aaawwwwwwwww *sadface*"
        else out = "Usage: #{RIB::TC}set pony [on|off|1|0]"
        end
        return nil, out
      end
    end
  end
end
