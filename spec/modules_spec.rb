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
        trigger /^(test)$/ do test("hi") end
      end

    let(:modul) { RIB::Module::Test }

    it 'sets a description' do
      expect(modul.descriptions[nil]).to eq('test module')
    end


    describe '#command' do
      it 'adds to @commands' do
        command = modul.commands.first
        expect(command).to be(:test)
      end
    end


    describe '#trigger' do
      it 'adds to @triggers' do
        response = modul.triggers[/^(test)$/]
        expect(response).to be_a(Proc)
      end
    end
  end
end


