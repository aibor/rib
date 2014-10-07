# coding: utf-8

require 'rib/connection'

RSpec.shared_examples 'connection' do
  describe RIB::Connection::Base do
    it 'inherits' do
      expect(conn.class.superclass).to be(RIB::Connection::Base)
    end
  end


  describe '#logging' do
    it 'creates Logging instance' do
      expect(conn.logging).to be_a(RIB::Connection::Logging)
    end

    it 'is deactivated' do
      expect(conn.logging.active).to be false
    end

    it 'can be activated' do
      expect { conn.togglelogging }.to change { conn.logging.active }.
        from(false).to(true)
    end
  end
end
