# coding: utf-8

require 'date'


RIB::Module.new :seen do
  desc 'Parse log files for information about a user.'

  protocol_only :irc

  command :seen, :who do
    desc 'Show when users were seen last and what were their last words'
    on_call do
      case who
      when nil, ''  then "#{user}: What? Try '!help seen'."
      when user     then "#{user}: Do you think that is funny? oO"
      else
        logger = bot.connection.logging.channels[source]
        logfile = logger.instance_variable_get('@logdev').filename

        out = "I haven't seen #{who}."

        File.readlines(logfile).reverse_each do |line|
          begin
            if line.encode!('UTF-8') =~ /^I,\s
              \[(\S+).\d+\s\#\d+\]\s+INFO\s               # get  time
              --\s:\s:((?i:#{who.gsub(/\|/,'\|')}))!\S+   # check nick
              \sPRIVMSG\s#{source.gsub(/#/,'\#')}\s       # check source
              :(.*)$                                      # get message
              /xi

              time = ::DateTime.parse($1).strftime('%F %R')
              out = "#{$2} was last seen at #{time}: #{$3}"
              break
            end
          rescue ArgumentError
          end
        end

        "#{user}: #{out}"
      end
    end
  end

end
