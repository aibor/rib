# coding: utf-8

#
# ### Helper functions ###
#

def formattitle(title)
  return nil if title.nil? || title.empty?
  case title 
  when /(\s+- YouTube\s*\Z)/ then
    "1,0You0,4Tube #{title.sub(/#{$1}/, "")}"
  when /(\Axkcd:\s)/ then
    "xkcd: #{title.sub(/#{$1}/, "")}"
  when /(\son\sdeviantART\Z)/ then
    "0,10deviantART #{title.sub(/#{$1}/, "")}"
  when /(\s+(-|–) Wikipedia((, the free encyclopedia)|)\Z)/ then
    "Wikipedia: #{title.sub(/#{$1}/, "")}"
  when /\A(dict\.cc \| )/ then
    "dict.cc: #{title.sub($1, "")}"
  when /(\ADer Postillon:\s)/ then
    "Der Postillon: #{title.sub($1, "")}"
  when /(\s+- Wolfram\|Alpha\s*\Z)/ then
    "Wolfram|Alpha: #{title.sub("#{$1}", "")}"
  else
    "Titel: #{title}"
  end
end

require 'cgi'
def gsearch( site, key )
  key = CGI.escape(key)
  url = case site
        when /wolf/ then
          "http://www.wolframalpha.com/input/?i=" + key
        when /w(iki)?/ then 
          "https://www.google.com/search?hl=de&btnI=1&q=site:wikipedia.org+#{key}&ie=utf-8&oe=utf-8&pws=0" 
        when /d(ict)?/ then 
          "http://dict.cc/?s=#{key}"
        else 
          "https://www.google.com/search?hl=de&btnI=1&q=#{key}&ie=utf-8&oe=utf-8&pws=0" 
        end
  10.times do |i|
    uri = URI.parse(URI.escape(url))
    http = Net::HTTP.new(uri.host)
    resp = http.request_head(uri.request_uri)
    break if url == resp['location'] || resp['location'].nil?
    url = resp['location']
  end
  url
end

require 'resolv'
def dnsrequest(host, nameserver)
  dns = Resolv::DNS.new(nameserver: nameserver)
  dns.getresource(host, Resolv::DNS::Resource::IN::TXT).strings
rescue Resolv::ResolvError
  "Can't resolv. Halp!"
end

#
# ### Response actions ###
#

responses = {
  "ping" => ["pong", "peng", "mowl!"],
  "hi"   => ["hi", "Moin!", "Tag", "Ahoj!", "Servus!"],
  "bye"  => ["nein?", "orrr, nö!", "selber!", "°_°"],
  "rage" => "(╯°□°)╯︵ ┻━┻",
  "panic" => ["http://rib.aibor.de/images/panic.gif",
              "http://rib.aibor.de/images/panic2.gif"],
  "alone" => "http://rib.aibor.de/images/forever_alone.png",
  "arch" => "http://rib.aibor.de/images/allan_sux.png",
  "deal" => "http://rib.aibor.de/images/dealwithit.gif",
  "chill" => "┬─┬ ノ( ゜-゜ノ)",
  "calm" => "http://rib.aibor.de/images/chill.jpg",
  "nope" => "http://rib.aibor.de/images/keep-calm-and-nope.png",
  "haha" => "http://rib.aibor.de/images/haha.jpg",
  "fucky" => "http://rib.aibor.de/images/fucky.jpg",
  "awesome" => ["http://rib.aibor.de/images/awesome.jpg",
                "http://rib.aibor.de/images/awesome2.jpg"],
  "#{rib.nick}" => "hell yeah!"
}

rib.add_response /\A#{rib.tc}(#{responses.keys.join('|')})\Z/ do |m,u,c|
  key = responses[m[1]]
  key.is_a?(Array) ? key[rand(key.length)] : key
end

quotes = {}
%w( bofh brba dexter ).each do |subject|
  quotefile = File.realpath("includes/#{subject}quotes")
  quotes[subject] = File.readlines(quotefile).each {|l| l.strip!}
end

rib.add_response /\A#{rib.tc}(#{quotes.keys.join('|')})(?:\s(\d+))?/ do |m,u,c|
  index = m[2].nil? ? 99999 : m[2].to_i.pred 
  '' + (quotes[m[1]][index] || quotes[m[1]].sample).split(/ \| /).join(': ')
end

require 'rib/html/html'
rib.add_response /\A(?!#{rib.tc}).*?(http[s]?:\/\/\S*)/x do |m,u,c|
  title = rib.title ? HTML.title(m[1]) : nil
  title.nil? || title.empty? ? nil : formattitle(title)
end

rib.add_response /\A.*?([p][o][n]{1,2}[yi][e]?s*)/i do |m,u,c|
  rib.pony && rand(2).zero? ? m[1] + " yay." : nil
end

rib.add_response /\A#{rib.tc}set (title|pony)\s*=?\s*(on|off|0|1)/i do |m,u,c|
  case m[2]
  when /on|1/ then 
    rib.send(m[1], true)
    m[1] == "title" ? "title turned on" : "ponies yay."
  when /off|0/ then 
    rib.send(m[1], false)
    m[1] == "title" ? "title turned off" : "aaawwwwwwwww *sadface*"
  else "Usage: #{rib.tc}set #{m[1]} [on|off|1|0]"
  end
end

rib.add_response /\A#{rib.tc}(g|wolf|dict|d) (.*)\Z/i do |m,u,c|
  found = gsearch(m[1], m[2])
  title = HTML.title(found) rescue ''
  '%s: %s\n%s' % [u, found, formattitle(title)]  
end

rib.add_response /\A#{rib.tc}(?:wiki|w) (.+)\Z/ do |m,u,c|
  dnsrequest( m[1].gsub(/\s/,'_') + ".wp.dg.cx", %w(208.67.220.220 208.67.222.222 8.8.8.8)).join('')
end

rib.add_response /\A((ACTION|\/me)\s+salutes()?)\Z/  do |m,u,c|
  m[1] + '\nI am Dave ! Yognaught and I have the balls!'
end

rib.add_response /\A#{rib.tc}blame (.+)/ do |m|
  "dafuq #{m[1]} oO"
end

rib.add_response /\A#{rib.tc}moar(?: (.+))?\z/ do |m|
  "MOAR #{m[1].strip}! MOAAR!!!1 "
end

alarms = {}
require 'rib/alarms'
rib.add_response /\A#{rib.tc}alarm(?: (\w+)(?: (\S+)(?: (.*))?)?)?\Z/ do |m,u,c,s|
  alarms[s] = AlarmBucket.new unless alarms[s].class == AlarmBucket
  case m[1]
  when 'list' then
    if alarms[s].empty?
      "#{u}: Currently no alarms active."
    else
      alarms[s].map.with_index do |thread,index|
        "#{index}: " + 
          ((thread[:date].strftime('%D') == Time.new.strftime('%D')) ? 
            "heute" : thread[:date].strftime('%v')) +
          " #{thread[:date].strftime('%T')} by #{thread[:user]} - #{thread[:msg]}"
      end.join(' --!!-- ')
    end
  when 'del' then
    if m[2] !~ /\A[0-9]\z/ or ! alarm = alarms[s][m[2]]
      "#{u}: No alarm found. Try again."
    elsif u != alarm[:user]
      "#{u}: dafuq? Who the hell are you? oO"
    else
      alarms[s].delete(m[2]) ? "#{u}: alarm deleted" : "#{u}: ouch, something went wrong :/"
    end
  when 'add' then
    date = Time.parse(m[2])
    if date <= Time.now
      "#{u}: This date is in the past! Try again."
    elsif alarms[s].full?
      "#{u}: Sorry, I already have 10 alarms to handle."
    elsif alarms[s].add(date, m[3], u, s) do |alarm|
        rib.say("ALARM added by #{alarm[:user]}: " + alarm[:msg],
                alarm[:source])
      end
      "#{u}: added alarm, stay tuned!"
    else
      "#{u}: dammit, something went wrong :\\"
    end
  else
    "#{u}: possible commands: list, del <[0-9]>, add <time> <msg>"
  end
end

require "./includes/bastelshare.rb"
bs = Bastelshare.new
bs.refresh
rib.add_response /\A#{rib.tc}bs(?: (\w+)(?: (.+))?)?\z/ do |m,u,c,s|
  cmd  = m[1]
  #args = m[2].split if args
  args = m[2]
  case cmd
  when 'refresh'
    bs.refresh( 5 ) ? "refreshed" : "Is noch neu! Geh weg!"
  when 'find'
    res = bs.find(args)
    if res.nil? or res.empty?
      "nope. try again!" 
    elsif res.count <= 3
      res.map(&:url).join(' --- ')
    else
      "too many results, not enough mics!"
    end
  else
    "possible commands: refresh, find <String>"
  end
end
