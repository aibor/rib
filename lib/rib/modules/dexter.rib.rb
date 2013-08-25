# coding: utf-8
module RIB
  module MyModules
    class Dexterquote < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}dexter/
      end
      
      def output( s, m, c )
        quotefile = File.expand_path("../dexterquotes", __FILE__)
        quotes = File.readlines(quotefile).each {|l| l.strip!}
        out = "Dexter says: " + quotes[rand(quotes.size)]
        return nil, out
      end

    end
  end
end
