# coding: utf-8

class RIB::Module::Fun < RIB::Module

  desc 'Gimme MOAR!'
  
  def moar(what)
    "MOAR #{what}! MOAAR!!!1 "
  end


  desc 'What the hell is wrong with her/him?'

  def blame(*who)
    "dafuq #{who * ' '} oO"
  end


  desc 'Punish a fellow user'

  def slap(who)
    hash = {
      "kicks #{who} in the ass" => 4,
      "slaps #{who} around with a large trout" => 4,
      "shakes head and goes away" => 1
    }

    "ACTION #{weighted_array(hash).sample}"
  end


  def kill(who)
    hash = {
      "steals #{who}'s network interface" => 5,
      "shoots #{msg.user}" => 1
    }

    "ACTION #{weighted_array(hash).sample}"
  end

  trigger(%r{\As/(.*?)/(.*?)/(g)?\Z}) do |match|
    line = bot.backlog.find { |m| m.user == msg.user }
    if line
      method = match[3] ? :gsub : :sub
      "#{msg.user}: #{line.text.send(method, match[1], match[2])}"
    end
  end


  trigger(/\A((?:ACTION|\/me)\s+salutes)\Z/) do |match|
    "#{match[1]}\nI am Dave ! Yognaught and I have the balls!"
  end


  private

  def weighted_array(hash)
    hash.flat_map { |msg, weight| [msg] * weight }
  end

end

