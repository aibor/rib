# coding: utf-8

require 'rib/command'

RSpec.describe RIB::Command do
  let(:command) do
    RIB::Command.new(:test, :modul, [:test_param], :irc) do
      desc 'test command'
      on_call { "invoked with arg: '#{test_param}'" }
    end
  end

  include_examples 'action', :test, 'test command' do
    let(:action) { command }
  end

  it 'sets params' do
    expect(command.params).to eq([:test_param])
  end
end
