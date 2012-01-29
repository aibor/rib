# coding: utf-8
module RIB
  module MyModules
    class Response
      RESP = { "hi"   => ["hi", "Moin!", "Tag"],
               "bye"  => ["nein?", "orrr, nö!"],
               "rage" => ["\\u0028\\u256f\\u00b0\\u25a1\\u00b0\\u0029\\u256f\\ufe35\\u0020\\u253b\\u2501\\u253b"]}
      TRIGGER = /\A#{RIB::TC}(hi|bye|rage)\Z/
      
      def output( s, m )
        key = RESP[m[1]]
        out = key[rand(key.length)]
        #out.gsub(/\\/, '\\\\') if RUBY_VERSION < '1.9'
        return nil, out
      end
    end
  end
end
