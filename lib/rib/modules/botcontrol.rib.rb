module RIB
  module MyModules
    def floodprot(int)
      int = 15 if ! int.is_a?(Fixnum)
      raise "flood protection" if ! @last.nil? and ( Time.new.to_i < (@last + int).to_i )
      @last = Time.new.to_i
    end
    class Quitbot
      TRIGGER = /\A#{RIB::TC}#{RIB::CONFIG.qcmd}/
      def output( s, m )
        $Server.quit(CONFIG.qmsg)
        $Log.info("Server left") if ! $Log.nil?
      end
    end
    class Uptime
      TRIGGER = /\A#{RIB::TC}uptime/i
      def output( m )
        return nil, "Uptime:\t" + timediff($Starttime)
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
        uptime << h.to_s + "h " if h > 0
        uptime << m.to_s + "m " if m > 0
        uptime << s.to_s + "s"
      end
    end
    class Givehelp
      TRIGGER = /\A#{RIB::TC}help(\sme)?/i

      def output( s, m )
        if ! CONFIG.helplink.nil?
          title = Pagetitle.new.ftitle(CONFIG.helplink).to_s
          output = CONFIG.helplink + "\n" + title
        else
          output = "Kein Link angegeben. :/" 
        end
        target = m[1].nil? ? nil : s
        return target, output
      end
    end
    class Botsay
      TRIGGER = /\A#{RIB::TC}say (.*)\Z/

      def output( s, m )
        return CONFIG.channel, m[1]
      end
    end
  end
end
