# coding: utf-8
module RIB
  module MyModules
    class Bofhquote < RIB::MyModulesBase
      def trigger
        /\A#{@bot.config.tc}bofh(?:\s(\d+))?/
      end
      
      def output( s, m, c )
        quotefile = File.expand_path("../bofhquotes", __FILE__)
        quotes = File.readlines(quotefile).each {|l| l.strip!}
        num = m[1].to_i.pred
        index = ((0..quotes.size.pred).include? num) ? num : rand(quotes.size)
        quote = quotes[index].split(/ \| /)
        out = "#{quote[0]}: " + quote[1]
        return nil, out
      end

    end
  end
end
