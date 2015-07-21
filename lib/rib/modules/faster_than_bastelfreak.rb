require 'json'
require'net/http'

class RIB::Module::FasterThanBastelfreak < RIB::Module

  describe ftb: 'Benchmark the given URL against bastelfreaks blog'
  
  BASE_URL = 'https://flipez.de/ftb/api?q='

  timeout ftb: 10

  def ftb url
    uri = URI(url)
    response = req uri
    score = parse_score response.body

    "#{uri.hostname} reached a FTB™ Score of #{score}"
  end

  private

  def req url
    uri = URI("#{BASE_URL}#{url}")
    Net::HTTP.get_response uri
  end

  def parse_score json
    result = JSON.parse(json)
    result['test']['result']
  end
end
