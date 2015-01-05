# coding: utf-8

require 'pstore'


class RIB::Module::Quotes < RIB::Module

  class << self
    attr_accessor :quotes
  end


  register quotes_file: 'data/quotes.pstore'


  Quote = Struct.new(:id, :msg, :by, :when) do

    def initialize(id, msg, by)
      super(id, msg, by, Time.now)
    end

  end


  on_init do
    @quotes ||= %i(bofh brba dexter).inject({}) do |quotes, subject|
      quotefile = File.absolute_path("../data/#{subject}quotes", __FILE__)
      quotes.merge(subject => File.readlines(quotefile).each {|l| l.strip!})
    end
  end


  desc 'Print a quote from Breaking Bad'
  def brba(number = nil)
    get_quote(:brba, number)
  end


  desc 'Print a quote from Dexter'
  def dexter(number = nil)
    get_quote(:dexter, number)
  end


  desc 'Print a BOFH excuse'
  def bofh(number = nil)
    get_quote(:bofh, number)
  end


  desc 'Grab last post of a user and save it as quote'
  def grab(who)
    return "meh!" if msg.user == who

    if match = bot.backlog.find { |m| m.user == who }
      user_quotes do |channel_quotes|
        id = channel_quotes.any? ? channel_quotes.last.id.next : 1
        channel_quotes << Quote.new(id, match, msg.user)
        "#{msg.user}: added quote ##{id}"
      end
    else
      "no :|"
    end
  end


  desc 'Get quote by id or last quote of a user or a random one'
  def quote(arg = nil)
    quote = case res = get_user_quotes(arg)
            when Quote then res
            when Array then arg ? res.last : res.sample
            else nil
            end

    "#{msg.user}: #{format(quote)}" if quote
  end


  desc 'Delete the quote with the particular id'
  def quotedel(id)
    return ["go away!", "°_°", "no?"].sample unless authorized?
    return "not a number" unless id[/\A\d+\z/]

    user_quotes do |channel_quotes|
      pre = channel_quotes.size
      channel_quotes.delete_if { |q| q.id == id.to_i }

      if channel_quotes.size != pre
        "#{msg.user}: deleted quote ##{id}"
      else
        "#{msg.user}: couldn't find quote ##{id}"
      end
    end
  end


  private

  def fetch_quote(subject, number = nil)
    if number && (number.is_a?(Fixnum) || number[/\A\d+\z/])
      quote = self.class.quotes[subject][number.to_i - 1]
    end
    quote ||= self.class.quotes[subject].sample
    quote.sub(/ \|/, ':')
  end


  def get_quote(subject, number = nil)
    res = fetch_quote(subject, number)
    res.sub!(/\A([^:]+:)/, '\1') if bot.config.protocol == :irc
    res
  end


  def user_quotes
    @user_quotes ||= ::PStore.new(bot.config.quotes_file)
    @user_quotes.transaction do
      server_arr = @user_quotes[bot.config.server] ||= {}
      yield(server_arr[msg.source] ||= [])
    end
  end


  def get_user_quotes(arg = nil)
    arg = arg.to_i if arg and arg[/\A\d+\z/]
    user_quotes do |channel_quotes|
      case arg
      when Integer
        channel_quotes.find { |q| q.id == arg }
      when String
        channel_quotes.select { |quote| quote.msg.user == arg }
      when nil
        channel_quotes
      else
        nil
      end
    end
  end


  def format(q)
    "Quote ##{q.id} added by #{q.by} at #{q.when.ctime}: #{q.msg.text}"
  end

end

