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


  context 'reply management' do

    describe '#reload_replies' do
      it 'loads replies' do
        expect { bot.reload_replies }.to change { bot.replies }.
          from(nil).to(Hash)
      end
    end


    describe '#add_reply' do
      it 'adds a reply ' do
        bot.reload_replies
        expect { bot.add_reply("test", "yo") }.to change { 
          bot.replies.to_a }. by([['test',['yo']]])
      end
    end


    describe '#delete_reply' do
      it 'deletes a reply ' do
        bot.reload_replies
        bot.add_reply("test", "yo")
        expect { bot.delete_reply("test", 0) }.to change { 
          bot.replies.keys.include?('test') }.from(true).to(false)
      end
    end

  end

end

