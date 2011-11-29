# coding: utf-8

def formattitle(title)
  case title 
  when /(\s+- YouTube\s*\Z)/ then return "1,0You0,4Tube #{title.sub(/#{$1}/, "")}"
  when /(\Axkcd:\s)/ then return "xkcd: #{title.sub(/#{$1}/, "")}"
  when /(\son\sdeviantART\Z)/ then return "0,10deviantART #{title.sub(/#{$1}/, "")}"
  when /(\s+(-|–) Wikipedia((, the free encyclopedia)|)\Z)/ then return "Wikipedia: #{title.sub(/#{$1}/, "")}"
  when /\A(dict\.cc \| )/ then return "dict.cc: #{title.sub($1, "")}"
  when /(\ADer Postillon:\s)/ then return "Der Postillon: #{title.sub($1, "")}"
  else return "Titel: #{title}"
  end # case title
end
