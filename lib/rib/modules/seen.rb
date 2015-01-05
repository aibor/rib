# coding: utf-8

require 'date'


class RIB::Module::Seen < RIB::Module

  desc 'Show when users were seen last and what were their last words'
  def seen(who)
    return unless bot.config.protocol == :irc

    case who
    when nil, ''  then "#{msg.user}: What? Try '!help seen'."
    when msg.user then "#{msg.user}: Do you think this is funny? oO"
    else "#{msg.user}: #{find_last_line(who)}"
    end
  end


  private

  def find_last_line(who)
    logfile = RIB::Connection::Logging.channel_file_path(
      bot.send(:log_path),
      bot.config.server,
      msg.source
    )

    return unless File.exist?(logfile)

    File.readlines(logfile).reverse_each do |line|
      if line.encode!('UTF-8') =~ /^
        ([\d-]+\s[\d:]+)\s                          # get time
        --\s:((?i:#{who.gsub(/\|/,'\|')}))!\S+      # check nick
        \sPRIVMSG\s#{msg.source.gsub(/#/,'\#')}\s   # check source
        :(.*)$                                      # get message
        /xi

        time = ::DateTime.parse($1).strftime('%F %R')
        return "#{$2} was last seen at #{time}: #{$3}"
      end
    end

    "I haven't seen #{who}."
  end

end

