# coding: utf-8

class RIB::Module::Quotes < RIB::Module::Base

  describe 'Quote Handler'


  init do
    @quotes ||= {}
    %i(bofh brba dexter).each do |subject|
      quotefile = File.absolute_path("../data/#{subject}quotes", __FILE__)
      @quotes[subject] = File.readlines(quotefile).each {|l| l.strip!}
    end
  end


  describe brba: 'Print a quote from Breaking Bad'

  def brba(number = nil)
    get_quote(:brba, number)
  end


  describe dexter: 'Print a quote from Dexter'

  def dexter(number = nil)
    get_quote(:dexter, number)
  end


  describe bofh: 'Print a BOFH excuse'

  def bofh(number = nil)
    get_quote(:bofh, number)
  end


  private

  def fetch_quote(subject, number = nil)
    puts number.inspect
    if number && (number.is_a?(Fixnum) || number[/\A\d+\z/])
      quote = @quotes[subject][number.to_i - 1]
      puts quote
    end
    quote ||= @quotes[subject].sample
    quote.sub(/ \|/, ':')
  end

  alias :get_quote :fetch_quote


  protocols_only :irc do

    def get_quote(subject, number = nil)
      fetch_quote(subject, number).sub(/\A([^:]+:)/, '\1')
    end

  end

end

