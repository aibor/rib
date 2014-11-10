# coding: utf-8

class RIB::Module::Fun < RIB::Module::Base

  describe 'Couple of useless commands'


  describe moar: 'Gimme MOAR!'
  
  def moar(what)
    "MOAR #{what}! MOAAR!!!1 "
  end


  describe blame: 'What the hell is wrong with her/him?'

  def blame(who)
    "dafuq #{who} oO"
  end


  response yognaught: /\A((?:ACTION|\/me)\s+salutes)\Z/


  private

  def yognaught(match)
    "#{match}\nI am Dave ! Yognaught and I have the balls!"
  end

end

