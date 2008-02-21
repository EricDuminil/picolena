PlainText.extract {
  from :txt, :text, :tex, :for, :cpp, :c, :rb, :ins, :vee, :java
  as "application/plain"
  aka "Plain text file"
  with {|source,destination|
    encoding=File.encoding(source)
    if encoding.empty? then
       FileUtils.cp source, destination
    else
       %x{iconv -f #{encoding} -t utf8  "#{source}" > "#{destination}" 2>/dev/null}
    end
  }
}