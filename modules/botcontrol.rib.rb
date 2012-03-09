# coding: utf-8

module RIB
  module MyModules
    module Botcontrol
      def floodprot(int)
        int = 15 if ! int.is_a?(Fixnum)
        raise "flood protection" if ! @last.nil? and ( Time.new.to_i < (@last + int).to_i )
        @last = Time.new.to_i
      end
      def commandlist
        list = MODS.commands.values.sort
        list.delete("quit")
        list
      end
    end

    class Quitbot
      TRIGGER = /\A#{RIB::TC}#{RIB::CONFIG.qcmd}/
      def output( s, m )
        RIB::Server.quit(CONFIG.qmsg)
        $Log.info("Server left") if ! $Log.nil?
      end
    end

    class Uptime
      TRIGGER = /\A#{RIB::TC}uptime/i
      HELP = "Zeige die Laufzeit und die Startzeit des Bots an. -- #{RIB::TC}uptime"

      def output( s, m )
        return nil, "Uptime: " + timediff($Starttime) + "   started: " + $Starttime.strftime("%d.%m.%Y %T %Z").to_s
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

    class Givehelp
      include Botcontrol
      TRIGGER = /\A#{RIB::TC}help(?:\s(.+))?/i
      HELP = "gibt Hilfetext für Befehle aus. -- !help <Befehl>"

      def output( s, m )
        out = s + ": "
        if m[1].nil?
          out << "!list zeigt alle Befehle an. -- !help <Befehl> gibt Hilfe zum Befehl aus."
          if ! CONFIG.helplink.nil?
            title = Pagetitle.new.ftitle(CONFIG.helplink).to_s
            out << " -- Übersicht über alle Befehle: " + CONFIG.helplink + "\n" + title
          else
            #out = "Kein Link angegeben. :/" 
          end
        elsif commandlist.flatten.include?(m[1])
          key = MODS.commands.select {|k, v| v.include?(m[1])}.keys[0]
          help = MODS.help[key]
          out << if help.is_a?(Hash)
                  help[m[1]]
                else
                  help
                end
          out << "Kann keinen Hilfetext für den Befehl '#{m[1]}' finden." if out.nil?
        else
          out << "Den Befehl '#{m[1]}' kenn ich nich."
        end
        return nil, out
      end
    end

    class Listcommands
      include Botcontrol
      TRIGGER = /\A#{RIB::TC}list(\sme)?/i
      HELP = "Liste alle Befehle auf. -- #{RIB::TC}list"

      def output( s, m )
        out = s + ": " + commandlist.join(', ')
        return nil, out
      end
    end

    class Botsay
      TRIGGER = /\A#{RIB::TC}say (.*)\Z/
      HELP = "Lass den Bot etwas im Channel sagen. -- #{RIB::TC}say <lauter Unsinn>"

      def output( s, m )
        return CONFIG.channel, m[1]
      end
    end
  end
end
