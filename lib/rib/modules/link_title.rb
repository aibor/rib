# coding: utf-8

require 'html/html'

RIB::Module.new :link_title do
  desc 'HTML title parser for URLs'

  on_load do |bot|
    bot.config.register(:title, true) unless bot.config.has_attr?(:title)
  end

    
  helpers do

    def formattitle(title)
      return nil if title.nil? || title.empty?
      case title 
      when /(\s+- YouTube\s*\Z)/ then
        "YouTube: #{title.sub(/#{$1}/, "")}"
      when /(\Axkcd:\s)/ then
        "xkcd: #{title.sub(/#{$1}/, "")}"
      when /(\son\sdeviantART\Z)/ then
        "deviantART: #{title.sub(/#{$1}/, "")}"
      when /(\s+(-|–) Wikipedia((, the free encyclopedia)|)\Z)/ then
        "Wikipedia: #{title.sub(/#{$1}/, "")}"
      when /(\ADer Postillon:\s)/ then
        "Der Postillon: #{title.sub($1, "")}"
      else
        "Title: #{title}"
      end
    end

  end


  protocol_only :irc do

    helpers do

      def formattitle(title)
        return nil if title.nil? || title.empty?
        case title 
        when /(\s+- YouTube\s*\Z)/ then
          "1,0You0,4Tube #{title.sub(/#{$1}/, "")}"
        when /(\Axkcd:\s)/ then
          "xkcd: #{title.sub(/#{$1}/, "")}"
        when /(\son\sdeviantART\Z)/ then
          "0,10deviantART #{title.sub(/#{$1}/, "")}"
        when /(\s+(-|–) Wikipedia((, the free encyclopedia)|)\Z)/ then
          "Wikipedia: #{title.sub(/#{$1}/, "")}"
        when /(\ADer Postillon:\s)/ then
          "Der Postillon: #{title.sub($1, "")}"
        else
          "Title: #{title}"
        end
      end

    end

  end


  response :html_title, /(http[s]?:\/\/\S*)/  do
    desc 'Get the HTML title if a URL is received'
    on_call do
      formattitle(HTML.title(match[1])) if bot.config.title
    end
  end


  command :title, :on_off do
    desc 'de-/activate HTML title parsing'
    on_call do
      if %w(on true 1).include? on_off
        bot.config.title = true
        "will try to parse HTML titles"
      elsif %w(off false 0).include? on_off
        bot.config.title = false
        "will not try to parse HTML titles"
      end
    end
  end

end
