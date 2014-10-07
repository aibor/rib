require 'rib'

rib = RIB::Bot.new do |bot|
  bot.server = "irc.example.org"
  bot.protocol = :irc
  bot.port = 6667
  bot.channel = '#rib'
  bot.qmsg = 'See you later, shitlords!'
  bot.debug = false
  bot.admin = 'ribmaster'
  bot.modules = [:core, :link_title, :quotes, :search, :fun, :alarm]
  bot.replies_file = 'replies.yml'
end


RSpec.describe RIB::Bot, "::new" do

  it "returns new instance" do
    expect(rib).to be_a(RIB::Bot)
  end

  it "has a config" do
    expect(rib.config).to be_a(RIB::Configuration)
  end

  it "got the right server" do
    expect(rib.config.server).to eq('irc.example.org')
  end

end
