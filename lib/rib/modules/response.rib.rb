# coding: utf-8
module RIB
  module MyModules
    class Response < RIB::MyModulesBase

      def trigger
        /\A#{@bot.config.tc}(#{resp.keys.join('|')})\Z/
      end

      def output( s, m, c )
        key = resp[m[1]]
        out = key.is_a?(Array) ? key[rand(key.length)] : key
        #out.gsub(/\\/, '\\\\') if RUBY_VERSION < '1.9'
        return nil, out
      end

      def resp
        {
          "hi"   => ["hi", "Moin!", "Tag", "Ahoj!", "Servus!"],
          "bye"  => ["nein?", "orrr, nö!", "selber!", "°_°"],
          # ruby > 1.9  "rage" => ["\\u0028\\u256f\\u00b0\\u25a1\\u00b0\\u0029\\u256f\\ufe35\\u0020\\u253b\\u2501\\u253b"]}
          "rage" => "(╯°□°)╯︵ ┻━┻",
          "panic" => ["https://dl.dropbox.com/u/6670723/images/panic.gif","https://dl.dropbox.com/u/6670723/images/panic2.gif"],
          "alone" => "https://dl.dropbox.com/u/6670723/images/forever_alone.png",
          "arch" => "http://xyne.archlinux.ca/img/misc/allan_sux.png",
          "deal" => "https://dl.dropbox.com/u/6670723/images/dealwithit.gif"
        }
      end
    end
  end
end
