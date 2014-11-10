# coding: utf-8

require 'html/html'


class RIB::Module::LinkTitle < RIB::Module::Base

  describe 'HTML title parser for URLs'


  register title: true


  describe html_title: 'Get the HTML title if a URL is received'

  response html_title: /(http[s]?:\/\/[-?&+%=_.~a-zA-Z0-9\/:]+)/


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
      ::Kernel.puts "url: #{url}"
      title = HTML.title(url)
      ::Kernel.puts "out: #{title}"
      formattitle(title)
    rescue RuntimeError => e
      e.message
    end
  end


  private

  def formattitle(title)
    return nil if title.nil? || title.empty?
    case title
      #when /(\s+- YouTube\s*\Z)/ then
      #  "YouTube: #{title.sub(/#{$1}/, "")}"
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


  protocols_only :irc do

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

