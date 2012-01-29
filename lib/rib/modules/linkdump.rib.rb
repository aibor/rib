# coding: utf-8

module RIB
  module MyModules
    module Linkdump
      LINKDUMP = File.expand_path("../" + CONFIG.linkdump, $0)
      def addentry( source, input )
        lines = String.new
        lines = "--------------------\n" if File.exist?(LINKDUMP)
        lines << Time.now.asctime << " - " 
        lines << source << " - " 
        lines << $Server.whois(source).auth << "\n" 
        lines << input << "\n"
        File.open(LINKDUMP, File::WRONLY | File::APPEND | File::CREAT) {|f| f.write(lines) }
        updatefile = File.dirname(LINKDUMP)+"/entries/.lastupdate"
        File.unlink(updatefile) if File.exist?(updatefile)
      end
      def getentryname( path, num )
        entrydir = File.dirname(path)+"/entries/"
        entryarr = Dir.entries(entrydir).sort.delete_if {|e| e =~ /\A\./}
        entrycnt = entryarr.size
        case  num
        when "r" then num = rand(entryarr.length)
        when "l" then num = -1
        else 
          if num < 0
            num += entrycnt
          else
            num -= 1 
          end
        end
        raise if num < -1
        entryarr[(num)] =~ /\A(\d+)-(.*?)-(.*?)\Z/
        [entrydir, $&, $1, $2, $3]
      end
      def readentry(file)
        f = File.open(file, File::RDONLY | File::NONBLOCK) 
        line = f.gets
        line =~ /\A<a href="(.*?)" target="_blank" title="(.*?)">(?:.*?)<\/a><br>\Z/
        load File.expand_path('../formattitle.rb', __FILE__)
        title = $2.empty? ? $2 : formattitle(HTML.unentit($2, "utf-8"))
        $1 + "\n" + title
      end 
    end
    class Addentry
      include Linkdump
      TRIGGER = /\A#{RIB::TC}add\s+(http[s]?:\/\/\S*)/xi 
      
      def output( s, m )
        if ! CONFIG.linkdump.nil?
          addentry(s, m[1])
        else
          return s, nil
        end
        begin
          title = Pagetitle.new.ftitle(m[1]).to_s + "\n"
        rescue
          title = nil
        end
        title = "" if title.nil?
        out = title + "Link added!"
        return nil, out
      end

    end
    class Delentry
      include Linkdump
      TRIGGER = /\A#{RIB::TC}del\s+(\d+)/

      def output ( s, m )
        num = m[1].to_i
        return [nil, "Nein!"] if CONFIG.linkdump.nil? or num < 1
        File.unlink(LINKDUMP) if File.exist?(LINKDUMP)
        entry = getentryname(LINKDUMP, num)
        return [nil, "Eintrag ##{num} nicht gefunden"] if entry[1].nil?
        return [nil, "Du nicht!"] if entry[4] != $Server.whois(source).auth
        File.unlink(entry[0]+entry[1])
        out = "Eintrag ##{num} gelöscht"
        return nil, out
      end
    end
    class Giveentry
      include Linkdump
      TRIGGER = /\A#{RIB::TC}give\s*(l|r|\d*)/i 

      def output( s, m )
        input = (m[1] or 0)
        if input =~ /\A[l|r]\Z/
          num = input
        else
          num = input.to_i 
        end
        return [s, "Kein Link angegeben. :/"] if CONFIG.dumplink.nil?
        begin
          raise if num =~ /[^lr]/
          raise if num.respond_to?("zero?") and num.zero?
          entry = getentryname(LINKDUMP, num)
          file = entry[0]+entry[1]
          raise if ! File.exist?(file)
          out = readentry(file)
        rescue
          url = CONFIG.dumplink
          title = Pagetitle.new.ftitle(url).to_s
          out = url + "\n" + title
        end
        return nil, out
      end
    end
  end
end
