# coding: utf-8
def floodprot(int)
  int = 15 if ! int.is_a?(Fixnum)
  raise "flood protection" if ! @last.nil? and ( Time.new.to_i < (@last + int).to_i )
  @last = Time.new.to_i
end

#add_response /\A#{self.tc}quit\s#{self.password}/ do 
add_response /\A#{self.tc}quit/ do |m,u,c|
  if u == self.admin and Time.now - @starttime > 5
    @server.quit(self.qmsg)
    @log.info("Server left") if @log.respond_to?("info")
  end
  nil
end

add_response /\A#{self.tc}join\s(#\w+)\s#{self.password}/ do |m|
  @server.join(m[1])
  nil
end

add_response /\A#{self.tc}part\s(#\w+)\s#{self.password}/ do |m|
  @server.part(m[1])
  nil
end

add_response /\A#{self.tc}uptime/i do
  "Uptime: " + timediff(@starttime) + "   started: " + @starttime.strftime("%d.%m.%Y %T %Z").to_s
end

def timediff( start )
  raise if ! start.is_a?(Time)
  diff = (Time.now - start).to_i
  s = diff.modulo(60)
  m = diff.modulo(3600)/60
  h = diff.modulo(3600*24)/3600
  d = diff/(3600*24)

  uptime = String.new
  uptime << d.to_s + "d " if d > 0
  uptime << sprintf("%#2d:%02d:%02d", h, m, s)
end

add_response /\A#{self.tc}list(\sme)?/i do |m,u|
  "#{u}: " + @callbacks.keys.map do |k|
    k.to_s =~ /\\A#{self.tc}\(?(?:\?\:)?(\w+(\|\w+|\s\w+)*)/
    next unless $1.respond_to? "split"
    $1.split(/\|/)
  end.join(', ')
end


