# coding: utf-8

RSpec.shared_examples 'action' do |name, desc|
  it 'sets name' do
    expect(action.name).to eq(name)
  end

  it 'sets description' do
    expect(action.description).to eq(desc)
  end

  it 'sets module name' do
    expect(action.module).to eq(:modul)
  end

  it 'sets action' do
    expect(action.action).to be_a(Proc)
  end

  describe '#call' do
    subject { action.call(msg: 'test yo') }

    it { is_expected.to be_a(String) }

    it { is_expected.to eq("invoked with arg: 'yo'") }

    it 'sets @last_call' do
      subject
      expect(action.last_call).to be_within(0.1).of(Time.new)
    end

    it "can't be called on init" do
      action.instance_eval { @init = false }
      is_expected.to be(false)
    end
  end

  describe '#speaks?' do
    it 'can be tested for one protocol' do
      expect(action.speaks?(:irc)).to be true
      expect(action.speaks?(:xmpp)).to be false
    end

    it 'can be tested for array of protocols' do
      expect(action.speaks?([:irc])).to be true
      expect(action.speaks?([:irc,:xmpp])).to be true
      expect(action.speaks?([:xmpp])).to be false
    end
  end
end

