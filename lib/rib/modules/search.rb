# coding: utf-8

require 'resolv'
require 'json'


class RIB::Module::Search < RIB::Module

  desc 'Search on Google for the passes string'
  def google(*args)
    format gsearch(:google, args)
  end

  alias :g :google


  register wiki_lang: :en


  #desc 'Search on Wikipedia using the DNS API'
  desc 'Search on Wikipedia using the Wikipedia API'
  def wikipedia(*args)
    #dnsrequest(args.join('_') + ".wp.dg.cx",
    #           %w(208.67.220.220 208.67.222.222 8.8.8.8)).join
    #format gsearch(:google, ['site:wikipedia.org'] + args)
    res = wikipedia_api(args, 1, bot.config.wiki_lang)
    "#{res[2].first} - #{res[3].first}" if res.last.any?
  end

  alias :w :wikipedia


  desc "Search on DuckDuckGo. Jumps to first search
    result, unless bang syntax is used. Try '!ddg !bang'"
  def duckduckgo(*args)
    format gsearch(:ddg, args)
  end

  alias :ddg :duckduckgo


  private

  def format(found)
    lt = RIB::Module::LinkTitle.new(bot, msg)
    title = lt.send(:formattitle, ::HTML.title(found)) rescue ''
    "%s: %s\n%s" % [msg.user, found, title]
  end


  def gsearch(site, keys)
    url = case site
          when :ddg
            keys.first.gsub!(/^[^!]/, '\\\\\&')
            'https://duckduckgo.com/html?q=%s' % keys.join('+')
          when :google
            "https://www.google.com/search?hl=de&btnI=1&q=" +
              "#{keys * '+'}&ie=utf-8&oe=utf-8&pws=0"
          end
    url = ::URI.escape(url)
    10.times do |i|
      uri = ::URI.parse(url)
      http = ::Net::HTTP.new(uri.host)
      resp = http.request_head(uri.request_uri)
      break if url == resp['location'] || resp['location'].nil?
      url = resp['location']
    end

    url
  end


  WikiApiURL = 'https://%s.wikipedia.org/w/api.php?action=opensearch' +
    '&search=%s&format=json&redirects=return&limit=%d'

  def wikipedia_api(keys, limit = 1, lang = :en)
    url = URI.escape(WikiApiURL % [lang, keys.join('+'), limit])
    ::JSON.parse ::Net::HTTP.get(URI(url))
  end


  def dnsrequest(host, nameserver)
    dns = ::Resolv::DNS.new(nameserver: nameserver)
    dns.getresource(host, ::Resolv::DNS::Resource::IN::TXT).strings
  rescue ::Resolv::ResolvError
    ["Can't resolv. Halp!"]
  end

end

