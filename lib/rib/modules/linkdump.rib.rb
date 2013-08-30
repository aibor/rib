# coding: utf-8
module RIB
  module MyModules

    module Linkdump

      def linkdump( location )
        File.expand_path("../" + location, $0).sub(/[^\/]\Z/, '\&/')
      end

      def addentry( location, source, input, title )
        title = input if title.nil?
        line = "<a href=\"#{input}\" target=\"_blank\" title=\"#{title}\">#{title}<\/a><br>\n"
        filename = Time.now.strftime("%s") + "-"
        filename << source << "-" 
        filename << @bot.server.whois(source).auth
        if ! File.exists?( location )
          require 'fileutils'
          FileUtils.mkdir_p( location )
        end
        File.open( location  + filename, File::WRONLY | File::CREAT) {|f| f.write(line) }
        File.chmod(0644,  location  + filename)
        #updatefile = File.dirname( location )+"/entries/.lastupdate"
        #File.unlink(updatefile) if File.exist?(updatefile)
      end

      def getentryarr( entrydir )
        Dir.entries(entrydir).sort.delete_if {|e| e !~ /\A\d+-.*?-.*?\Z/}
      end

      def getentryname( entrydir, num )
        entryarr = getentryarr(entrydir)
        num = getentrynum( entryarr, num )
        entryarr[(num)] =~ /\A(\d+)-(.*?)-(.*?)\Z/
        [entrydir, $&, $1, $2, $3, num.next]
      end

      def getentrynum( entryarr, num )
        entrycnt = entryarr.size
        case  num
        when "r" then num = rand(entryarr.length)
        when "l" then num = entrycnt - 1
        else 
          num = entrycnt if num > entrycnt
          if num < 0
            if num.abs > entrycnt
              num = 0
            else
              num += entrycnt
            end
          else
            num -= 1 
          end
        end
        num
      end

      def readentry(file)
        f = File.open(file, File::RDONLY | File::NONBLOCK) 
        line = f.gets
        line =~ /\A<a href="(.*?)" target="_blank" title="(.*?)">(?:.*?)<\/a><br>\Z/
        load File.expand_path('../../formattitle.rb', __FILE__)
        title = $2.empty? ? $2 : formattitle(HTML.unentit($2, "utf-8"))
        $1 + "\n" + title
      end 

      def searchentry( entrydir, key )
        entries = Array.new
        getentryarr(entrydir).each_with_index do |entry, index|
          content = readentry(entrydir + entry).sub(/\n/, ' - ')
          if content.sub(/.+/, '').downcase.include?(key.downcase)
            entries.push("##{index.next}: " + content)
          end
        end
        entries.join(' -- ')[0..350]
      end
    end # module Linkdump

    class Addentry < RIB::MyModulesBase
      include Linkdump
      def trigger
        /\A#{@bot.config.tc}add\s+(http[s]?:\/\/\S*)(\s+(.+))?\Z/xi 
      end
      def help
        "#{@bot.config.tc}add http://harharhar.de -- URL in den Linkdump eintragen."
      end
      
      def output( s, m, c )
        if @bot.config.linkdump.nil?
          return nil, nil
        end
        if m[3].nil?
          begin
            require 'rib/html/html'
            title = HTML.title(m[1]).to_s
          rescue
            title = nil
          end
        else
          title = m[3]
        end
        addentry( linkdump( @bot.config.linkdump), s, m[1], title)
        load File.expand_path('../../formattitle.rb', __FILE__)
        title = title.nil? ? "" : "#{formattitle(HTML.unentit(title, 'utf-8'))}\n"
        out = title + s + ": Link ##{getentryname( linkdump( @bot.config.linkdump ), "l" )[5]} hinzugefügt"
        return nil, out
      end

    end
    class Delentry < RIB::MyModulesBase
      include Linkdump
      def trigger
        /\A#{@bot.config.tc}del\s+(l|-?\d+)/
      end
      def help
        "#{@bot.config.tc}del <Eintragsnummer> -- Lösche Eintrag aus dem Linkdump. Nur wer den Eintrag angelegt hat, kann ihn löschen."
      end

      def output ( s, m, c )
        if m[1] =~ /\A[l|r]\Z/
          num = m[1]
        else
          num = m[1].to_i 
        end
        return [nil, "Nein!"] if @bot.config.linkdump.nil? or ( num.respond_to?("zero?") and num.zero? )
        entry = getentryname( linkdump( @bot.config.linkdump ), num )
        return [nil, "Eintrag ##{num} nicht gefunden"] if entry[1].nil?
        return [nil, "Du nicht!"] if entry[4] != @bot.server.whois(s).auth
        File.unlink(entry[0]+entry[1])
        out = s + ": Eintrag ##{entry[5]} gelöscht!"
        return nil, out
      end
    end
    class Giveentry < RIB::MyModulesBase
      include Linkdump
      def trigger
        /\A#{@bot.config.tc}(?:give|link)(?:\s+(l|r|-?\d+))?/i 
      end
      def help
        {"give" => "#{@bot.config.tc}give[ <l|r|-1|3|-4|...> -- Gib eine URL aus dem Linkdump aus.",
				"link" => "#{@bot.config.tc}link[ <l|r|-1|3|-4|...> -- Gib eine URL aus dem Linkdump aus."}
      end


      def output( s, m, c )
        input = (m[1] or 0)
        if input =~ /\A[l|r]\Z/
          num = input
        else
          num = input.to_i 
        end
        begin
          raise if num =~ /[^lr]/
          raise if num.respond_to?("zero?") and num.zero?
          entry = getentryname( linkdump( @bot.config.linkdump ), num )
          file = entry[0]+entry[1]
          raise if ! File.exist?(file)
          out = "Link ##{entry[5]}: " + readentry(file)
        rescue
          if @bot.config.dumplink.nil?
            out = "Kein Link angegeben. :/"
          else
            url = @bot.config.dumplink
            title = Pagetitle.new.ftitle(url).to_s
            out = url + "\n" + title
          end
        end
        return nil, s + ": " + out
      end
    end

    class Searchentry < RIB::MyModulesBase
      include Linkdump
      def trigger
        /\A#{@bot.config.tc}search (.*)\Z/
      end
      def help
        "#{@bot.config.tc}search <Suchstring> -- Sucht im Linkdump nach dem Suchstring."
      end

      def output( s, m, c )
        found = searchentry( linkdump( @bot.config.linkdump ), m[1] )
        found = "Nichts gefunden!" if found.empty?
        out = s + ": " + found
        return nil, out
      end
    end

  end
end
