# coding: utf-8
module RIB
  module MyModules
    class Bofhquote < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}bofh/
      end
      
      def output( s, m, c )
        quotefile = File.expand_path("../bofhquotes", __FILE__)
        quotes = File.readlines(quotefile).each {|l| l.strip!}
        quote = quotes[rand(quotes.size)].split(/ \| /)
        out = "#{quote[0]}: " + quote[1]
        return nil, out
      end

    end
  end
end
