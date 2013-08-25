# coding: utf-8
module RIB
  module MyModules

    module Botcontrol
      def floodprot(int)
        int = 15 if ! int.is_a?(Fixnum)
        raise "flood protection" if ! @last.nil? and ( Time.new.to_i < (@last + int).to_i )
        @last = Time.new.to_i
      end
    end

    class Quitbot < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}quit\s#{@bot.config.password}/
      end
      def help
        "!quit <Passwort> -- Bot disconnected vom Server und beendet sich."
      end
      def output( s, m, c )
        @bot.server.quit(@bot.config.qmsg)
        @bot.log.info("Server left") if @bot.log.respond_to?("info")
        return nil
      end
    end

		class Joinchannel < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}join\s(#\w+)\s#{@bot.config.password}/
      end
      def help
        "!join <Channel> <Passwort> -- Läßt den Bot einen Channel betreten."
      end

			def output( s, m, c)
				@bot.server.join(m[1])
				return nil
			end
		end

		class Partchannel < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}part\s(#\w+)\s#{@bot.config.password}/
      end
      def help
        "!part <Channel> <Passwort> -- Läßt den Bot den Channel verlassen."
      end

			def output( s, m, c)
				@bot.server.part(m[1])
				return nil
			end
		end

		class Reloadmodules < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}reload\s#{@bot.config.password}/
      end
      def help
        "!reload <Passwort> -- Liest die Module erneut ein."
      end

			def output( s, m, c)
				if @bot.load_modules
          "geschafft"
        else
          "kaputt"
        end
			end
		end

    class Uptime < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}uptime/i
      end
      def help
        "#{@bot.config.tc}uptime -- Zeige die Laufzeit und die Startzeit des Bots an."
      end

      def output( s, m, c )
        return nil, "Uptime: " + timediff(@bot.starttime) + "   started: " + @bot.starttime.strftime("%d.%m.%Y %T %Z").to_s
      end
      def timediff( start )
        raise if ! start.is_a?(Time)
        diff = (Time.now - start).to_i
        s = diff.modulo(60)
        m = diff.modulo(3600)/60
        h = diff.modulo(3600*24)/3600
        d = diff/(3600*24)

        uptime = String.new
        uptime << d.to_s + "d " if d > 0
        uptime << sprintf("%#2d:%02d:%02d", h, m, s)
      end
    end

    class Givehelp < RIB::MyModulesBase
      include Botcontrol
      def trigger
        /\A#{@bot.config.tc}help(?:\s(.+))?/i
      end
      def help
        "!help <Befehl> -- Gibt Hilfetext für Befehle aus."
      end

      def output( s, m, c )
        if m[1].nil?
          out = "!list zeigt alle Befehle an. -- !help <Befehl> gibt Hilfe zum Befehl aus."
          unless @bot.config.helplink.nil?
            begin
              title = "\n" + Pagetitle.ftitle(@bot.config.helplink).to_s
            rescue ArgumentError
              true
            end
            out << " -- Übersicht über alle Befehle: " + @bot.config.helplink + title.to_s
          else
            #out = "Kein Link angegeben. :/" 
          end
        else 
          @bot.modules.each do |mod|
            next unless mod.respond_to? "help"
            help = mod.help 
            next if help.nil?
            if help.is_a?(Hash)
              out = help[m[1]]
            elsif help =~ /\A(?:#{@bot.config.tc})?#{m[1]}/
              out = help 
            end
          end
          out = "Kann keinen Hilfetext für den Befehl '#{m[1]}' finden." if out.nil?
        end
        return nil, s + ": " + out
      end
    end

    class Listcommands < RIB::MyModulesBase
      include Botcontrol
      def trigger
        /\A#{@bot.config.tc}list(\sme)?/i
      end
      def help
        "#{@bot.config.tc}list -- Liste alle Befehle auf."
      end

      def output( s, m, c )
        out = s + ": " + @bot.get_commands.flatten.delete_if{|s| s == "quit"}.join(', ')
        return nil, out
      end
    end

    class Botsay < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}say (.*)\Z/
      end
      def help
        "#{@bot.config.tc}say <lauter Unsinn> -- Lass den Bot etwas im Channel sagen."
      end

      def output( s, m, c )
        return @bot.config.channel, m[1]
      end
    end
  end
end
