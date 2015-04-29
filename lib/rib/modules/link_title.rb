# coding: utf-8

require 'html/html'


class RIB::Module::LinkTitle < RIB::Module

  describe 'HTML title parser for URLs'


  register title: true


  describe html_title: 'Get the HTML title if a URL is received'


  trigger(/(http[s]?:\/\/[-?&+%=_.,~a-zA-Z0-9\/:]+)/) do |match|
    html_title(match[1])
  end


  describe title: 'de-/activate HTML title parsing'

  def title(on_off)
    if %w(on true 1).include? on_off
      bot.config.title = true
      "will try to parse HTML titles"
    elsif %w(off false 0).include? on_off
      bot.config.title = false
      "will not try to parse HTML titles"
    end
  end


  def html_title(url)
    return unless bot.config.title
    begin
      puts "url: #{url}"
      title = HTML.title(url)
      puts "out: #{title}"
      formattitle(title)
    rescue HTML::NoTitleFoundError
      nil
    rescue => e
      bot.logger.error e
      #e.message
      nil
    end
  end


  private

  def formattitle(title)
    return nil if title.nil? || title.empty?
    if bot.config.protocol== :irc
      return nil if title.nil? || title.empty?
      case title
      when /(\s+- YouTube\s*\Z)/
        "1,0You0,4Tube #{title.sub(/#{$1}/, "")}"
      when /(\Axkcd:\s)/
        "xkcd: #{title.sub(/#{$1}/, "")}"
      when /(\son\sdeviantART\Z)/
        "0,10deviantART #{title.sub(/#{$1}/, "")}"
      when /(\s+(-|–) Wikipedia((, the free encyclopedia)|)\Z)/
        "Wikipedia: #{title.sub(/#{$1}/, "")}"
      when /(\ADer Postillon:\s)/
        "Der Postillon: #{title.sub($1, "")}"
      when /\A([^:]+) (?:on|auf) Twitter: "(.*)"\z/
        "#{$1}: #{$2}"
      else
        "Title: #{title}"
      end
    else
      case title
        #when /(\s+- YouTube\s*\Z)/
        #  "YouTube: #{title.sub(/#{$1}/, "")}"
      when /(\Axkcd:\s)/
        "xkcd: #{title.sub(/#{$1}/, "")}"
      when /(\son\sdeviantART\Z)/
        "deviantART: #{title.sub(/#{$1}/, "")}"
      when /(\s+(-|–) Wikipedia((, the free encyclopedia)|)\Z)/
        "Wikipedia: #{title.sub(/#{$1}/, "")}"
      when /(\ADer Postillon:\s)/
        "Der Postillon: #{title.sub($1, "")}"
      when /\A([^:]+) (?:on|auf) Twitter: "(.*)"\z/
        "#{$1}: #{$2}"
      else
        "Title: #{title}"
      end
    end
  end

end

