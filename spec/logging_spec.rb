# coding: utf-8

require 'rib/connection'

RSpec.describe RIB::Connection::Logging do
  include TestFilesSetup

  let(:logging) do
    described_class.new(test_log_dir, 'localhost')
  end

  it 'inherits from Struct' do
    expect(described_class.superclass.superclass).to be(Struct)
  end

  it 'raises if path is not a String' do
    expect { described_class.new(33, 'localhost') }.to \
      raise_error(TypeError)
  end

  it 'raises if hostname is not a String' do
    expect { described_class.new(test_log_dir, 33) }.to \
      raise_error(TypeError)
  end

  it 'creates server Logger instance' do
    expect(logging.server).to be_a(Logger)
    expect(Dir.entries(test_log_dir)).to include('localhost.log')
  end

  it 'can add channel log' do
    expect { logging.add_channel_log('#test') }.to \
      change { logging.channels.keys }.by(%w(#test))
    expect(Dir.entries(test_log_dir)).to include('localhost_#test.log')
  end
end
