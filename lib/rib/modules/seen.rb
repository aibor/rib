# coding: utf-8

require 'date'


RIB::Module.new :seen do
  desc 'Parse log files for information about a user.'


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
          if line =~ /^I,\s
            \[(\S+).\d+\s\#\d+\]                  # get date and time
            \s+INFO\s--\s:\s:#{who}!\S+\s         # check the nickname
            PRIVMSG\s#{source.gsub(/#/,'\#')}\s   # check the source
            :(.*)$                                # get the message
            /x

            time = ::DateTime.parse($1).strftime('%F %R')
            out = "#{who} was last seen at #{time}: #{$2}"
            break
          end
        end

        "#{user}: #{out}"
      end
    end
  end

end
