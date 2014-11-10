# coding: utf-8

require 'rib'

RSpec.shared_examples 'bot instance' do |klass|
  include TestFilesSetup
  
  before do
    wayne = Logger.new('/dev/null')
    allow(Logger).to receive(:new).and_return(wayne)
  end


  describe '#init_connection' do
    let(:init) { bot.instance_eval { init_connection } }

    it 'creates Connection' do
      expect(init).to be_a(klass)
    end
  end


  context 'from user perspective' do
    it 'can be configured' do
      bot.configure { |b| b.logdir = '123' }
      expect(bot.config.logdir).to eq('123')
    end
  end

end

