require'net/http'

class RIB::Module::WhatTheCommit < RIB::Module

  URL = 'http://whatthecommit.com/index.txt'

  describe 'Get the best commit message at your fingertips'
  def wtc
    uri = URI(URL)
    response = Net::HTTP.get_response uri

    response.body.chomp
  end
end
