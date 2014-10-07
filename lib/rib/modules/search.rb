# coding: utf-8

require 'cgi'
require 'resolv'

RIB::Module.new :search do
  desc 'Google search'

  helpers do

    def gsearch(site, key)
      key = ::CGI.escape(key)

      url = case site
            when :wiki
              "https://www.google.com/search?hl=de&btnI=1&q=site:wikipedia.org+" +
                "#{key}&ie=utf-8&oe=utf-8&pws=0"
            when :google
              "https://www.google.com/search?hl=de&btnI=1&q=" +
                "#{key}&ie=utf-8&oe=utf-8&pws=0"
            end
      10.times do |i|
        uri = ::URI.parse(::URI.escape(url))
        http = ::Net::HTTP.new(uri.host)
        resp = http.request_head(uri.request_uri)
        break if url == resp['location'] || resp['location'].nil?
        url = resp['location']
      end

      url
    end


    def dnsrequest(host, nameserver)
      dns = ::Resolv::DNS.new(nameserver: nameserver)
      dns.getresource(host, ::Resolv::DNS::Resource::IN::TXT).strings
    rescue ::Resolv::ResolvError
      ["Can't resolv. Halp!"]
    end

  end


  command :g do
    desc 'Search on Google for the passes string'
    on_call do
      found = gsearch(:google, msg.split[1..-1].join(' '))
      title = formattitle(::HTML.title(found)) rescue ''
      '%s: %s\n%s' % [user, found, title]
    end
  end


  command :w do
    desc 'Search on Wikipedia using the DNS API'
    on_call do
      dnsrequest(msg.split[1..-1].join('_') + ".wp.dg.cx",
                 %w(208.67.220.220 208.67.222.222 8.8.8.8)).join
    end
  end

end
