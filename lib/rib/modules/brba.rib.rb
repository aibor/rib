# coding: utf-8
module RIB
  module MyModules
    class Brbaquote < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}brba/
      end
      
      def output( s, m, c )
        quotefile = File.expand_path("../brbaquotes", __FILE__)
        quotes = File.readlines(quotefile).each {|l| l.strip!}
        quote = quotes[rand(quotes.size)].split(/ \| /)
        out = "#{quote[0]} says: " + quote[1]
        return nil, out
      end

    end
  end
end
