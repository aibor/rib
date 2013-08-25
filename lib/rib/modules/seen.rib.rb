# coding: utf-8
module RIB
  module MyModules
    class Lastseen < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}seen\s+(\S+)/
      end
        def help
          "Show time and content of someone's last privmsg"
        end

      def readlog( channel, nick )
        logfilepath = File.expand_path("../log/#{@bot.config.irc}_#{channel}.log", $0)
        return nil if channel.nil? or nick.nil? or ! File.exists?(logfilepath)
        logfile = File.new(logfilepath)
        log = logfile.readlines
        log.reverse.each do |entry|
          begin
            if entry.match(/[^:]+--\s:\s:#{nick}!\S+\sPRIVMSG/)
              return entry
            end
          rescue
            next
          end
        end
        nil
      end

      def gettime( string )
        require 'date'
        DateTime.parse(string).strftime('%d.%m.%Y, %H:%M')
      end

      # s = source of message, m = matchdata of TRIGGER-regexp
      def output( s, m, c )
        channel = c.params[0].match(/\A#/).nil? ? nil : c.params[0]
        entry = readlog( channel, m[1] )
        if entry.nil?
          if m[1] == "mich"
            result = " -_- lame!"
          else
            result = "Ich habe #{m[1]} hier noch nie gesehen."
          end
        else
          entry =~ /\AI, \[(\S+).\d+\s\#\d+\]\s+INFO\s--\s:\s:[^:]+:(.*)\Z/
          time = gettime($1)
          result = "#{m[1]} wurde zuletzt am #{time} Uhr gesehen: \"#{$2}\"" 
        end
        out = s + ": " + result
        return nil, out
      end

    end
  end
end
