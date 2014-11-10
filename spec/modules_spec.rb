# coding: utf-8

require 'rib/module'

RSpec.describe RIB::Module do
  describe '.new' do

      class RIB::Module::Test < RIB::Module::Base
        describe 'test module'
        register test_directive: '666'
        describe test: 'test command'
        def test(test_param)
          "command invoked with arg: '#{test_param}'"
        end
        response test: /^(test)$/
      end

    let(:modul) { RIB::Module::Test }

    it 'sets a description' do
      expect(modul.description[nil]).to eq('test module')
    end


    describe '#command' do
      it 'adds to @commands' do
        command = modul.commands.first
        expect(command).to be(:test)
      end
    end


    describe '#response' do
      it 'adds to @responses' do
        response = modul.responses[:test]
        expect(response).to eq(/^(test)$/)
      end
    end
  end
end


