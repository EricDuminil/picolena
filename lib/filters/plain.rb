PlainText.extract {
  from :txt, :text, :tex, :for, :cpp, :c, :rb, :ins, :vee, :java
  as "application/plain"
  aka "Plain text file"
  with {some_ruby_magic_coming_soon}
}

#  def plain_to_utf8_text(src,dst)
#    encoding=File.encoding(src)
#    if encoding.empty? then
#       FileUtils.cp src, dst
#    else
#       %x{iconv -f #{encoding} -t utf8  SOURCE > DESTINATION 2>/dev/null}
#    end
#    raise 'missing iconv(1) command' if $?.exitstatus == 127
#    raise "failed to convert plain text file: #{src}" unless $?.exitstatus == 0    
#  end