# coding: utf-8

module RIB
  module MyModules
    class Websearch
      TRIGGER = /\A#{RIB::TC}(g|wolf|dict|d) (.*)\Z/i
      HELP = {
        "g" => "#{RIB::TC}g <Suchstring> -- Suche bei Google.",
        "dict" => "#{RIB::TC}g <Suchstring> -- Wörterbuchsuche bei Dict.cc.",
        "d" => "#{RIB::TC}g <Suchstring> -- Wörterbuchsuche bei Dict.cc.",
        "wolf" => "#{RIB::TC}wolf <Suchstring> -- Suche bei Wolfram|Alpha."
      }
      
      def output( s, m, c )
        site = m[1]
        key = m[2].to_s
        output = s + ": " + gsearch(site, key)
        return [target, nil] if output.nil?
        begin
          title = "\n" + Pagetitle.new.ftitle(output).to_s
        rescue
          title = nil
        end
        title = "" if title.nil?
        output << title 
        return nil, output
      end

      def gsearch( site, key )
        if RUBY_VERSION > '1.9'
          key.encode!("utf-8", "iso-8859-1") if key.encoding.name != "UTF-8"
        else
          key = Iconv.iconv("utf-8", "iso-8859-1", key).to_s
        end
        key.gsub!(/\s/, "+")
        case site
          when /wolf/ then url = "http://www.wolframalpha.com/input/?i=" + key
          when /w(iki)?/ then url = "https://www.google.com/search?hl=de&btnI=1&q=site:wikipedia.org+#{key}&ie=utf-8&oe=utf-8&pws=0" 
          when /d(ict)?/ then url = "http://dict.cc/?s=#{key}"
          else url = "https://www.google.com/search?hl=de&btnI=1&q=#{key}&ie=utf-8&oe=utf-8&pws=0" 
        end
        count = 10
        while ! url.nil?
          out = url
          uri = URI.parse(URI.escape(url))
          http = Net::HTTP.new(uri.host)
          resp = http.request_head(uri.request_uri)
          break if url == resp['location']
          url = resp['location']
          count.zero? ? break : (count = count - 1) 
        end
        out
      end
    end
  end
end
