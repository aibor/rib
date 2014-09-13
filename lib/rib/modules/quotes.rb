# coding: utf-8

RIB::Module.new :quotes do
  desc 'Quote Handler'

  quotes = {}
  %w(bofh brba dexter).each do |subject|
    quotefile = File.absolute_path($0 + "/../data/#{subject}quotes")
    quotes[subject] = File.readlines(quotefile).each {|l| l.strip!}
  end

  helpers do

    Quotes = quotes

    def fetch_quote(subject, number = nil)
      quote = Quotes[subject][number.to_i - 1] if number and number[/\A\d+\z/]
      quote ||= Quotes[subject].sample
      quote.sub(/ \|/, ':')
    end

    alias :get_quote :fetch_quote

  end


  protocol_only :irc do

    helpers do

      def get_quote(subject, number = nil)
        fetch_quote(subject, number).sub(/\A([^:]+:)/, '\1')
      end

    end

  end


  command :brba, :number do
    desc 'Print a quote from Breaking Bad'
    on_call { get_quote('brba', number) }
  end


  command :dexter, :number do
    desc 'Print a quote from Dexter'
    on_call { get_quote('dexter', number) }
  end


  command :bofh, :number do
    desc 'Print a BOFH excuse'
    on_call { get_quote('bofh', number) }
  end

end
