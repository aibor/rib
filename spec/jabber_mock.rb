# coding: utf-8

class JabberMock

  class << self

    attr_accessor :debug

  end


  class Client

    attr_accessor :jid

    def initialize(jid)
      @jid = jid
      @to_send = []
      @received = []
    end


    def connect
    end


    def auth(*args)
    end


    def send(msg)
      @received << msg
    end


    def received
      @received.shift
    end

    def close
    end


    def add_iq_callback(&block)
      iq = Iq.new
      iq.type = :get
      iq.queryns = ''
      yield iq
    end

  end

  class JID

    attr_accessor :node

    def initialize(*args)
    end

  end

  class Presence

    def initialize(*args)
    end


    def set_type(*args)
      self
    end

  end

  class MUC

    class SimpleMUCClient

      def initialize(*args)
        @received = []
      end


      def join(*args)
      end


      def say(msg)
        @received << msg
      end


      def received
        @received.shift
      end


      def on_message(&block)
        yield Time.new, 'tester', '!test'
      end

    end

  end

  class Iq

    attr_accessor :type, :queryns, :id, :from, :to

    def initialize(*args)
    end

  end

end


RSpec.shared_examples 'jabber_mock' do
  before { stub_const('Jabber',JabberMock) }
  #let(:server) { bot.connection }
end

