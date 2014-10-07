# coding: utf-8

require 'rib/module'

RSpec.describe RIB::Module do
  describe '.new' do
    before { RIB::Module.empty_loaded }

    let(:modul) do
      RIB::Module.new :test do
        desc 'test module'
        on_load { bot.config.register :test_directive, '666' }
        command :test, :test_param do
          desc 'test command'
          on_call { "command invoked with arg: '#{test_param}'" }
        end
        response :test, /^test$/ do
          desc 'test response'
          on_call { 'triggered response' }
        end
      end
    end

    it 'raises on wrong name arg' do
      expect { RIB::Module.new(23) { true } }.to \
        raise_error(NoMethodError)
    end

    it 'raises on duplicate name' do
      expect { 2.times { RIB::Module.new(:name) { true } } }.to \
        raise_error(RIB::DuplicateModuleError)
    end

    it 'sets a name' do
      expect(modul.name).to eq(:test)
    end

    it 'sets a description' do
      expect(modul.description).to eq('test module')
    end


    describe '#command' do
      it 'adds to @commands' do
        command = modul.commands.first
        expect(command).to be_a(RIB::Command)
        expect(command.name).to be(:test)
      end
    end


    describe '#response' do
      it 'adds to @responses' do
        response = modul.responses.first
        expect(response).to be_a(RIB::Response)
        expect(response.name).to be(:test)
      end
    end
  end
end


