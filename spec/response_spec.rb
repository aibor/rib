# coding: utf-8

require 'rib/response'

RSpec.describe RIB::Response do
  let(:response) do
    RIB::Response.new(:test, :modul, /^test (\w+)$/, :irc) do
      desc 'test response'
      on_call { "invoked with arg: '#{match[1]}'" }
    end
  end

  include_examples 'action', :test, 'test response' do
    let(:action) { response }
  end

  it 'sets trigger' do
    expect(response.trigger).to eq(/^test (\w+)$/)
  end
end
